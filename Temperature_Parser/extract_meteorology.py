import time
import logging
from pathlib import Path
from typing import Optional, Tuple

import pandas as pd

from utils.file_utils import get_data_files
from apis.open_meteo_api import get_temperature
from apis.geo_api import get_lat_lon

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")


def _first_nonempty(row: pd.Series, keys):
    """
    Return the first non-empty value from the row for the given keys (in order).
    row: pandas Series representing a row from the dataframe
    keys: iterable of column names to check in order
    Returns None if no valid value found.
    """
    
    for k in keys:
        v = row.get(k)
        if v is not None and str(v).strip() != "":
            return v
    return None


def get_date_range(row: pd.Series) -> Optional[Tuple[str, str]]:
    """
    Extract start and end dates from a row, returning as ISO format strings (YYYY-MM-DD).
    Prefer DHINICIO/DHFIM. Otherwise DATAALERTA + HORAALERTA or DATAALERTA alone.
    row: pandas Series representing a row from the dataframe
    Returns None if no valid start date found.
    """

    # Prefer DHINICIO/DHFIM. Otherwise DATAALERTA + HORAALERTA or DATAALERTA alone.
    start_raw = _first_nonempty(row, ("DHINICIO", "DhInicio", "dhinicio"))
    end_raw = _first_nonempty(row, ("DHFIM", "DhFim", "dhfim"))
    if start_raw:
        start = pd.to_datetime(start_raw, dayfirst=True, errors="coerce")
    else:
        da = _first_nonempty(row, ("DATAALERTA", "DataAlerta", "dataalerta"))
        ha = _first_nonempty(row, ("HORAALERTA", "HoraAlerta", "horaalerta"))
        start = pd.to_datetime(f"{da} {ha}" if ha else da, dayfirst=True, errors="coerce") if da else pd.NaT

    if end_raw:
        end = pd.to_datetime(end_raw, dayfirst=True, errors="coerce")
    else:
        de = _first_nonempty(row, ("DATAEXTINCAO", "DataExtincao", "dataextincao"))
        he = _first_nonempty(row, ("HORAEXTINCAO", "HoraExtincao", "horaextincao"))
        end = pd.to_datetime(f"{de} {he}" if he else de, dayfirst=True, errors="coerce") if de else pd.NaT

    if pd.isna(start):
        return None
    if pd.isna(end):
        end = start
    return start.date().isoformat(), end.date().isoformat()


def process_file(path: Path, out_dir: Path, incident_col: str = "id"):
    """
    Process a single CSV file to extract meteorological data for each incident.
        path: input CSV file path
        out_dir: output directory for results
        incident_col: name of the column with unique incident identifier (default "id")
    """
    logging.info(f"Processing {path.name}")
    try:
        df = pd.read_csv(path, sep="|", dtype=str, low_memory=False)
    except Exception as e:
        logging.warning(f"Failed reading {path}: {e}")
        return

    df.columns = [c.strip() for c in df.columns]
    records = []

    for _, row in df.iterrows():
        # Get incident ID
        incident_id = _first_nonempty(row, (incident_col, incident_col.upper(), incident_col.lower()))
        if not incident_id:
            continue

        lat = row.get("LAT") or row.get("Lat") or row.get("lat")
        lon = row.get("LON") or row.get("Lon") or row.get("lon")
        if not lat or not lon:
            logging.debug(f"No coords for incident {incident_id} in {path.name}")
            continue

        # Get date range
        date_range = get_date_range(row)
        if not date_range:
            logging.debug(f"No valid date for incident {incident_id} in {path.name}")
            continue
        start_date, end_date = date_range

        # Call API to get temperature data
        try:
            daily = get_temperature(float(lat), float(lon), start_date, end_date)
        except Exception as e:
            logging.warning(f"API error for {incident_id} ({lat},{lon}) : {e}")
            continue

        # Extract daily data
        times = daily.get("time", [])
        tmax = daily.get("temperature_2m_max", [])
        tmin = daily.get("temperature_2m_min", [])

        # Append records for each day in range to results list (for later DataFrame creation)
        for i, d in enumerate(times):
            records.append({
                "incident_id": incident_id,
                "source_file": path.name,
                "date": d,
                "lat": lat,
                "lon": lon,
                "temp_max": tmax[i] if i < len(tmax) else None,
                "temp_min": tmin[i] if i < len(tmin) else None,
            })

        time.sleep(0.5)  # be polite

    # Write detailed and summary CSVs (delegated)
    write_output_csvs(records, out_dir, path.stem)


def write_output_csvs(records, out_dir: Path, stem: str):
    """
    Write detailed time-series CSV and per-incident summary CSV for a given input file stem.
    If records is empty, write empty files with headers so downstream jobs don't break.
        records: list of dicts with keys:
        incident_id, source_file, date, lat, lon, temp_max, temp_min
        out_dir: output directory
        stem: base name for output files
    """
    out_base = Path(out_dir)
    out_base.mkdir(parents=True, exist_ok=True)
    detailed_path = out_base / f"meteorology_{stem}.csv"
    summary_path = out_base / f"summary_{stem}.csv"

    if records:
        detailed = pd.DataFrame(records)
        # persist raw detailed rows
        detailed.to_csv(detailed_path, index=False)

        # ensure numeric for aggregation
        detailed["temp_max"] = pd.to_numeric(detailed.get("temp_max"), errors="coerce")
        detailed["temp_min"] = pd.to_numeric(detailed.get("temp_min"), errors="coerce")

        summary = detailed.groupby("incident_id", as_index=False).agg(
            start_date=("date", "min"),
            end_date=("date", "max"),
            mean_temp_max=("temp_max", "mean"),
            mean_temp_min=("temp_min", "mean"),
            n_days=("date", "nunique"),
            lat=("lat", "first"),
            lon=("lon", "first"),
        )
        summary.to_csv(summary_path, index=False)
        logging.info(f"Wrote {detailed_path.name} and {summary_path.name}")
    else:
        # write empty files with headers so downstream jobs don't break
        cols_det = ["incident_id", "source_file", "date", "lat", "lon", "temp_max", "temp_min"]
        pd.DataFrame(columns=cols_det).to_csv(detailed_path, index=False)
        pd.DataFrame(columns=["incident_id", "start_date", "end_date", "mean_temp_max", "mean_temp_min", "n_days", "lat", "lon"]).to_csv(summary_path, index=False)
        logging.info(f"No records for {stem} — wrote empty files.")


def run(data_dir: str = "data", out_dir: str = "output/meteorology"):
    files = get_data_files(data_dir, pattern="*.csv", recursive=False)
    if not files:
        logging.error("No CSV files found.")
        return
    out_base = Path(out_dir)
    for f in files:
        process_file(Path(f), out_base)


if __name__ == "__main__":
    run()