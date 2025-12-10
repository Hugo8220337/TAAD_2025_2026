import datetime
import time
import logging
import argparse
from pathlib import Path
import pandas as pd
import pyodbc
import pypyodbc

# Mantendo as importações das suas APIs existentes
from apis.open_meteo_api import get_temperature
# from utils.file_utils import get_data_files # Não é mais necessário

# Configuração de Logs
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s",
                   handlers=[
                       logging.FileHandler("meteorology_extract.log"),
                       logging.StreamHandler()
                   ])

def get_best_odbc_driver(prefer=("ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server", "SQL Server Native Client 11.0", "SQL Server")):
    """
    Deteta o melhor driver ODBC instalado (Lógica trazida do main.py)
    """
    try:
        available = [d for d in pyodbc.drivers()]
    except Exception:
        # Fallback se pyodbc não listar, tenta pypyodbc ou retorna vazio
        return None
        
    for pref in prefer:
        for a in available:
            if pref.lower() in a.lower():
                return a
    return available[0] if available else None

def get_db_connection(connection_string):
    """
    Estabelece conexão com a BD
    """
    driver = get_best_odbc_driver()
    if driver:
        # Garante que o driver está na string se ainda não estiver
        if "Driver={" not in connection_string:
            connection_string = "Driver={" + driver + "};" + connection_string
        logging.info(f"Using ODBC Driver: {driver}")
    else:
        logging.warning("No ODBC Driver found or pyodbc generic lookup failed. Trying string as provided.")

    try:
        # Tenta conectar via pypyodbc (conforme o seu main.py)
        cnxn = pypyodbc.connect(connection_string, timeout=10)
        return cnxn
    except Exception as e:
        logging.error(f"Failed to connect to DB: {e}")
        raise

def date_id_to_iso(date_id):
    """
    Converte int YYYYMMDD (ex: 20250211) para string 'YYYY-MM-DD'.
    Retorna None se inválido.
    """
    if pd.isna(date_id) or date_id == 0:
        return None
    try:
        s = str(int(date_id))
        if len(s) != 8:
            return None
        return f"{s[:4]}-{s[4:6]}-{s[6:]}"
    except:
        return None

def fetch_fire_data(connection_string, table_name="fact_fire"):
    """
    Lê os dados necessários da tabela de factos.
    """
    query = f"""
    SELECT 
        fire_id,
        latitude,
        longitude,
        start_day_id,
        end_day_id
    FROM {table_name}
    WHERE latitude IS NOT NULL 
      AND longitude IS NOT NULL
      AND start_day_id IS NOT NULL
    """
    
    logging.info("Connecting to Database to fetch fire incidents...")
    cnxn = get_db_connection(connection_string)
    
    try:
        # Pandas read_sql é mais eficiente para trazer dados para DataFrame
        df = pd.read_sql(query, cnxn)
        logging.info(f"Fetched {len(df)} rows from {table_name}")
        return df
    finally:
        cnxn.close()

def process_incidents(df: pd.DataFrame, out_dir: Path):
    """
    Processa o DataFrame carregado do SQL e chama a API.
    """
    start_time = time.time()
    records = []
    
    success_count = 0
    failed_date = 0
    failed_api = 0
    
    # Checkpoint: Se houver muitos dados, guardamos em chunks ou no final.
    # Aqui vamos guardar num único ficheiro, mas fazer appends periódicos seria melhor para volumes gigantes.
    output_file = out_dir / "meteorology_from_db.csv"
    
    total_rows = len(df)
    progress_interval = 10

    for idx, row in df.iterrows():
        if idx > 0 and idx % progress_interval == 0:
            elapsed_so_far = time.time() - start_time
            avg_time_per_record = elapsed_so_far / idx
            estimated_remaining = avg_time_per_record * (total_rows - idx)
            logging.info(f"Progress: {idx}/{total_rows} ({idx/total_rows*100:.1f}%) - Est. remaining: {estimated_remaining/60:.1f} min")

        incident_id = row['fire_id']
        lat = row['latitude']
        lon = row['longitude']
        
        # Conversão das datas (Inteiro YYYYMMDD -> YYYY-MM-DD)
        start_date = date_id_to_iso(row['start_day_id'])
        end_date = date_id_to_iso(row['end_day_id'])

        # Lógica de fallback se não houver data de fim
        if not start_date:
            failed_date += 1
            logging.debug(f"Invalid start date for {incident_id}")
            continue
            
        if not end_date:
            end_date = start_date # Assume duração de 1 dia se null

        try:
            api_start = time.time()
            # Chama a API (mantida do seu código original)
            daily = get_temperature(float(lat), float(lon), start_date, end_date)
            logging.debug(f"API call for {incident_id} took {time.time() - api_start:.2f}s")
        except Exception as e:
            logging.warning(f"API error for {incident_id} ({lat},{lon}) : {e}")
            failed_api += 1
            continue

        # Processamento da resposta da API (mantido do original)
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
        
        success_count += 1
        time.sleep(0.4) # Rate limiting

    # Guardar resultados
    write_output_csv(records, output_file)
    
    elapsed = time.time() - start_time
    logging.info(f"Completed processing in {elapsed:.2f}s - Successful: {success_count}, Failed dates: {failed_date}, API errors: {failed_api}")

def write_output_csv(records, output_path: Path):
    """
    Escreve o CSV final
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    if records:
        df_out = pd.DataFrame(records)
        df_out.to_csv(output_path, index=False)
        logging.info(f"Wrote {len(df_out)} weather records to {output_path}")
    else:
        logging.warning("No records were extracted.")

def run(db_connection: str, out_dir: str, table_name: str):
    # 1. Obter dados do SQL Server
    try:
        df_incidents = fetch_fire_data(db_connection, table_name)
    except Exception as e:
        logging.error("Stopping execution due to DB error.")
        return

    if df_incidents.empty:
        logging.warning("No incidents found in database with valid coordinates.")
        return

    # 2. Processar meteorologia
    process_incidents(df_incidents, Path(out_dir))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Extract meteorological data based on DB Fact Table')

    parser.add_argument(
        '--db_connection', '-d',
        type=str,
        required=True,
        # Exemplo padrão, ajustar conforme necessário
        default="Server=localhost,1433;Database=TAAD_DB;UID=sa;PWD=yourpassword",
        help='Database connection string'
    )

    parser.add_argument(
        '--table_name', '-t',
        type=str,
        default='fact_fire',
        help='Name of the fact table (default: fact_fire)'
    )

    parser.add_argument(
        '--output_dir', '-o',
        type=str,
        default='output/meteorology',
        help='Output directory for results'
    )

    args = parser.parse_args()

    logging.info(f"Extract Meteorology (DB Mode) started at {datetime.datetime.now()}")
    
    try:
        run(db_connection=args.db_connection, out_dir=args.output_dir, table_name=args.table_name)
        logging.info("Script completed successfully.")
    except Exception as e:
        logging.exception(f"Script failed with error: {e}")