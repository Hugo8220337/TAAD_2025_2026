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

        # Call API to get meteorological data
        try:
            daily = get_temperature(float(lat), float(lon), start_date, end_date)
        except Exception as e:
            logging.warning(f"API error for {incident_id} ({lat},{lon}) : {e}")
            continue

        # Extract daily data
        times = daily.get("time", [])
        tmax = daily.get("temperature_2m_max", [])
        tmin = daily.get("temperature_2m_min", [])
        # Humidade relativa
        rh_max = daily.get("relative_humidity_2m_max", [])
        rh_min = daily.get("relative_humidity_2m_min", [])
        # Precipitação
        precip = daily.get("precipitation_sum", [])
        rain = daily.get("rain_sum", [])
        precip_hours = daily.get("precipitation_hours", [])
        # Vento
        wind_max = daily.get("windspeed_10m_max", [])
        gust_max = daily.get("windgusts_10m_max", [])
        wind_dir = daily.get("winddirection_10m_dominant", [])
        # Radiação e sol
        radiation = daily.get("shortwave_radiation_sum", [])
        sunshine = daily.get("sunshine_duration", [])
        # Evapotranspiração
        et0 = daily.get("et0_fao_evapotranspiration", [])

        # Append records for each day in range to results list (for later DataFrame creation)
        for i, d in enumerate(times):
            records.append({
                "incident_id": incident_id,
                "source_file": path.name,
                "date": d,
                "lat": lat,
                "lon": lon,
                # Temperatura
                "temp_max": tmax[i] if i < len(tmax) else None,
                "temp_min": tmin[i] if i < len(tmin) else None,
                # Humidade relativa
                "rh_max": rh_max[i] if i < len(rh_max) else None,
                "rh_min": rh_min[i] if i < len(rh_min) else None,
                # Precipitação
                "precip_sum": precip[i] if i < len(precip) else None,
                "rain_sum": rain[i] if i < len(rain) else None,
                "precip_hours": precip_hours[i] if i < len(precip_hours) else None,
                # Vento
                "wind_max": wind_max[i] if i < len(wind_max) else None,
                "gust_max": gust_max[i] if i < len(gust_max) else None,
                "wind_dir": wind_dir[i] if i < len(wind_dir) else None,
                # Radiação e sol
                "radiation": radiation[i] if i < len(radiation) else None,
                "sunshine": sunshine[i] if i < len(sunshine) else None,
                # Evapotranspiração
                "et0": et0[i] if i < len(et0) else None,
            })

        time.sleep(0.5)  # be polite

    # Write detailed and summary CSVs (delegated)
    write_output_csvs(records, out_dir, path.stem)


def write_output_csvs(records, out_dir: Path, stem: str):
    """
    Write detailed time-series CSV and per-incident summary CSV for a given input file stem.
    If records is empty, write empty files with headers so downstream jobs don't break.
        records: list of dicts with keys:
        incident_id, source_file, date, lat, lon, temp_max, temp_min, rh_max, rh_min,
        precip_sum, rain_sum, precip_hours, wind_max, gust_max, wind_dir, 
        radiation, sunshine, et0
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
        for col in ["temp_max", "temp_min", "rh_max", "rh_min", "precip_sum", "rain_sum", 
                   "precip_hours", "wind_max", "gust_max", "wind_dir", "radiation", 
                   "sunshine", "et0"]:
            if col in detailed.columns:
                detailed[col] = pd.to_numeric(detailed.get(col), errors="coerce")

        # Criação do dataframe de resumo
        agg_dict = {
            "date": ["min", "max", "nunique"],
            "lat": "first",
            "lon": "first"
        }
        
        # Adiciona médias para todos os campos numéricos meteorológicos
        for col in ["temp_max", "temp_min", "rh_max", "rh_min", "precip_sum", "rain_sum", 
                   "precip_hours", "wind_max", "gust_max", "wind_dir", "radiation", 
                   "sunshine", "et0"]:
            if col in detailed.columns:
                agg_dict[col] = ["mean", "max", "min"]
                
        # Calcula valores derivados (dias sem chuva, dias com muito vento, etc.)
        if "precip_sum" in detailed.columns:
            detailed["dry_day"] = (detailed["precip_sum"] < 1.0).astype(int)
            agg_dict["dry_day"] = "sum"
            
        if "wind_max" in detailed.columns:
            detailed["high_wind"] = (detailed["wind_max"] > 30.0).astype(int)  # >30km/h (~8.3m/s)
            agg_dict["high_wind"] = "sum"

        # Executa a agregação
        summary_raw = detailed.groupby("incident_id").agg(agg_dict)
        
        # Renomeia as colunas para um formato mais limpo
        summary_raw.columns = ["_".join(col).strip() if isinstance(col, tuple) else col for col in summary_raw.columns.values]
        
        # Renomeia algumas colunas para manter compatibilidade com o formato anterior
        rename_dict = {
            "date_min": "start_date", 
            "date_max": "end_date",
            "date_nunique": "n_days",
            "temp_max_mean": "mean_temp_max",
            "temp_min_mean": "mean_temp_min",
        }
        summary = summary_raw.rename(columns=rename_dict).reset_index()
        
        summary.to_csv(summary_path, index=False)
        logging.info(f"Wrote {detailed_path.name} and {summary_path.name}")
    else:
        # write empty files with headers so downstream jobs don't break
        cols_det = ["incident_id", "source_file", "date", "lat", "lon", 
                  "temp_max", "temp_min", "rh_max", "rh_min", 
                  "precip_sum", "rain_sum", "precip_hours", 
                  "wind_max", "gust_max", "wind_dir", 
                  "radiation", "sunshine", "et0"]
        pd.DataFrame(columns=cols_det).to_csv(detailed_path, index=False)
        
        # Colunas para o resumo - mantém compatibilidade com versão anterior e adiciona novas métricas
        summary_cols = ["incident_id", "start_date", "end_date", "n_days", "lat", "lon",
                       "mean_temp_max", "temp_max_max", "temp_max_min",
                       "mean_temp_min", "temp_min_max", "temp_min_min",
                       "rh_max_mean", "rh_min_mean", 
                       "precip_sum_mean", "precip_sum_max", "rain_sum_mean",
                       "wind_max_mean", "wind_max_max", "gust_max_mean",
                       "wind_dir_mean", "radiation_mean", "sunshine_mean", "et0_mean",
                       "dry_day_sum", "high_wind_sum"]
        pd.DataFrame(columns=summary_cols).to_csv(summary_path, index=False)
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