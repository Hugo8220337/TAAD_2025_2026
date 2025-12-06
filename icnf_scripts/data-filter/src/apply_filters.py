import datetime
import time
import logging
import argparse  # <--- Adicionado
from pathlib import Path
from typing import Optional, Tuple
import pandas as pd
import os

from utils.file_utils import get_data_files
from apis.open_meteo_api import get_temperature
from apis.geo_api import get_lat_lon

# Configuração de Logs
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s",
                   handlers=[
                       logging.FileHandler("meteorology_extract.log"),
                       logging.StreamHandler()
                   ])

def _first_nonempty(row: pd.Series, keys):
    """
    Return the first non-empty value from the row for the given keys (in order).
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
    """
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
    """
    start_time = time.time()
    path_obj = Path(path) # Garante que é um objeto Path
    logging.info(f"Processing {path_obj.name}")
    
    try:
        df = pd.read_csv(path_obj, sep="|", dtype=str, low_memory=False)
        logging.info(f"Loaded {path_obj.name} with {len(df)} rows and {len(df.columns)} columns")
    except Exception as e:
        logging.warning(f"Failed reading {path_obj}: {e}")
        return

    df.columns = [c.strip() for c in df.columns]
    records = []
    success_count = 0
    failed_coords = 0
    failed_date = 0
    failed_api = 0

    progress_interval = 10

    for idx, row in df.iterrows():
        if idx > 0 and idx % progress_interval == 0:
            elapsed_so_far = time.time() - start_time
            avg_time_per_record = elapsed_so_far / idx if idx > 0 else 0
            estimated_remaining = avg_time_per_record * (len(df) - idx)
            logging.info(f"Progress: {idx}/{len(df)} rows ({idx/len(df)*100:.1f}%) - Est. remaining: {estimated_remaining/60:.1f} min")
       
        incident_id = _first_nonempty(row, (incident_col, incident_col.upper(), incident_col.lower()))
        if not incident_id:
            logging.warning(f"Missing incident ID in row {idx} of {path_obj.name}")
            continue

        lat = row.get("LAT") or row.get("Lat") or row.get("lat")
        lon = row.get("LON") or row.get("Lon") or row.get("lon")
        if not lat or not lon:
            logging.debug(f"No coords for incident {incident_id} in {path_obj.name}")
            failed_coords += 1
            continue

        date_range = get_date_range(row)
        if not date_range:
            logging.debug(f"No valid date for incident {incident_id} in {path_obj.name}")
            failed_date += 1
            continue
        start_date, end_date = date_range

        try:
            api_start = time.time()
            daily = get_temperature(float(lat), float(lon), start_date, end_date)
            api_time = time.time() - api_start
            logging.debug(f"API call for {incident_id} took {api_time:.2f}s")
        except Exception as e:
            logging.warning(f"API error for {incident_id} ({lat},{lon}) : {e}")
            failed_api += 1
            continue

        times = daily.get("time", [])
        tmax = daily.get("temperature_2m_max", [])
        tmin = daily.get("temperature_2m_min", [])
        rh_max = daily.get("relative_humidity_2m_max", [])
        rh_min = daily.get("relative_humidity_2m_min", [])
        precip = daily.get("precipitation_sum", [])
        rain = daily.get("rain_sum", [])
        precip_hours = daily.get("precipitation_hours", [])
        wind_max = daily.get("windspeed_10m_max", [])
        gust_max = daily.get("windgusts_10m_max", [])
        wind_dir = daily.get("winddirection_10m_dominant", [])
        radiation = daily.get("shortwave_radiation_sum", [])
        sunshine = daily.get("sunshine_duration", [])
        et0 = daily.get("et0_fao_evapotranspiration", [])

        day_count = 0
        for i, d in enumerate(times):
            records.append({
                "incident_id": incident_id,
                "source_file": path_obj.name,
                "date": d,
                "lat": lat,
                "lon": lon,
                "temp_max": tmax[i] if i < len(tmax) else None,
                "temp_min": tmin[i] if i < len(tmin) else None,
                "rh_max": rh_max[i] if i < len(rh_max) else None,
                "rh_min": rh_min[i] if i < len(rh_min) else None,
                "precip_sum": precip[i] if i < len(precip) else None,
                "rain_sum": rain[i] if i < len(rain) else None,
                "precip_hours": precip_hours[i] if i < len(precip_hours) else None,
                "wind_max": wind_max[i] if i < len(wind_max) else None,
                "gust_max": gust_max[i] if i < len(gust_max) else None,
                "wind_dir": wind_dir[i] if i < len(wind_dir) else None,
                "radiation": radiation[i] if i < len(radiation) else None,
                "sunshine": sunshine[i] if i < len(sunshine) else None,
                "et0": et0[i] if i < len(et0) else None,
            })
            day_count += 1

        logging.debug(f"Added {day_count} days of data for incident {incident_id}")
        success_count += 1
        time.sleep(0.4) 

    elapsed = time.time() - start_time
    logging.info(f"Completed {path_obj.name} in {elapsed:.2f}s - Successful: {success_count}, Failed coords: {failed_coords}, Failed dates: {failed_date}, API errors: {failed_api}")
    
    write_output_csvs(records, out_dir, path_obj.stem)


def write_output_csvs(records, out_dir: Path, stem: str):
    """
    Write detailed time-series CSV and per-incident summary CSV.
    """
    out_base = Path(out_dir)
    out_base.mkdir(parents=True, exist_ok=True)
    detailed_path = out_base / f"meteorology_{stem}.csv"
    summary_path = out_base / f"summary_{stem}.csv"

    if records:
        detailed = pd.DataFrame(records)
        detailed.to_csv(detailed_path, index=False)

        for col in ["temp_max", "temp_min", "rh_max", "rh_min", "precip_sum", "rain_sum", 
                   "precip_hours", "wind_max", "gust_max", "wind_dir", "radiation", 
                   "sunshine", "et0"]:
            if col in detailed.columns:
                detailed[col] = pd.to_numeric(detailed.get(col), errors="coerce")

        agg_dict = {
            "date": ["min", "max", "nunique"],
            "lat": "first",
            "lon": "first"
        }
        
        for col in ["temp_max", "temp_min", "rh_max", "rh_min", "precip_sum", "rain_sum", 
                   "precip_hours", "wind_max", "gust_max", "wind_dir", "radiation", 
                   "sunshine", "et0"]:
            if col in detailed.columns:
                agg_dict[col] = ["mean", "max", "min"]
                
        if "precip_sum" in detailed.columns:
            detailed["dry_day"] = (detailed["precip_sum"] < 1.0).astype(int)
            agg_dict["dry_day"] = "sum"
            
        if "wind_max" in detailed.columns:
            detailed["high_wind"] = (detailed["wind_max"] > 30.0).astype(int)
            agg_dict["high_wind"] = "sum"

        summary_raw = detailed.groupby("incident_id").agg(agg_dict)
        summary_raw.columns = ["_".join(col).strip() if isinstance(col, tuple) else col for col in summary_raw.columns.values]
        
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
        cols_det = ["incident_id", "source_file", "date", "lat", "lon", 
                  "temp_max", "temp_min", "rh_max", "rh_min", 
                  "precip_sum", "rain_sum", "precip_hours", 
                  "wind_max", "gust_max", "wind_dir", 
                  "radiation", "sunshine", "et0"]
        pd.DataFrame(columns=cols_det).to_csv(detailed_path, index=False)
        
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
    logging.info(f"Starting meteorological data extraction from {data_dir} to {out_dir}")
    start_time = time.time()
    
    files = get_data_files(data_dir, pattern="*.csv", recursive=False)
    if not files:
        logging.error(f"No CSV files found in {data_dir}")
        return
        
    logging.info(f"Found {len(files)} CSV files to process")
    out_base = Path(out_dir)
    
    for i, f in enumerate(files):
        logging.info(f"Processing file {i+1}/{len(files)}: {f}")
        process_file(Path(f), out_base)
    
    elapsed = time.time() - start_time
    logging.info(f"Extraction complete! Processed {len(files)} files in {elapsed:.2f}s")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Extract meteorological data for fire incidents')

    parser.add_argument(
        '--data_dir', '-i',
        type=str,
        default='./data',
        help='Input directory containing CSV files (default: ./data)'
    )

    parser.add_argument(
        '--output_dir', '-o',
        type=str,
        default='output/meteorology',
        help='Output directory for meteorological files (default: output/meteorology)'
    )

    args = parser.parse_args()

    logging.info(f"Extract Meteorology Script started at {datetime.datetime.now()}")
    logging.info(f"Arguments: data_dir={args.data_dir}, output_dir={args.output_dir}")
    
    try:
        run(data_dir=args.data_dir, out_dir=args.output_dir)
        logging.info(f"Script completed successfully at {datetime.datetime.now()}")
    except Exception as e:
        logging.exception(f"Script failed with error: {e}")