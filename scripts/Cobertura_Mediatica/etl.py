import json
import pandas as pd
import sqlalchemy as sa
from sqlalchemy.exc import SQLAlchemyError
from datetime import datetime
import urllib.parse
import argparse
import sys
import os
import pyodbc  # Necessário para listar os drivers instalados

# -------------------------------------------------------------------------
# HELPER: DRIVER DETECTION
# -------------------------------------------------------------------------
def get_best_odbc_driver(prefer=("ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server", "SQL Server Native Client 11.0", "SQL Server")):
    """
    Detecta o melhor driver ODBC disponível no sistema baseado na lista de preferência.
    """
    try:
        available = [d for d in pyodbc.drivers()]
        if not available:
            return None
        
        for pref in prefer:
            for a in available:
                if pref.lower() in a.lower():
                    return a
        return available[0]
    except Exception:
        return None

# -------------------------------------------------------------------------
# 1. EXTRACT
# -------------------------------------------------------------------------
def extract_data(file_path):
    print(f"--- Extracting Data from {file_path} ---")
    try:
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
            
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"Loaded {len(data)} raw records.")
        return data
    except Exception as e:
        print(f"Error reading file: {e}")
        sys.exit(1)

# -------------------------------------------------------------------------
# 2. VALIDATE AND SEGREGATE
# -------------------------------------------------------------------------
def process_data(data):
    print("--- Validating Data ---")
    valid_records = []
    quarantine_records = []
    
    for row in data:
        try:
            # --- A. Type Validation ---
            raw_date = row.get('data_publicacao')
            if not raw_date:
                raise ValueError("Missing 'data_publicacao'")
            try:
                # Format: 'Fri, 15 Dec 2023 10:00:00 GMT'
                dt_obj = datetime.strptime(raw_date, '%a, %d %b %Y %H:%M:%S GMT')
            except ValueError:
                raise ValueError(f"Invalid date format: {raw_date}")

            raw_risk = row.get('risk_score')
            risk_val = 0
            if raw_risk is not None:
                try:
                    risk_val = int(float(raw_risk))
                except (ValueError, TypeError):
                    raise ValueError(f"Invalid risk_score type: {raw_risk}")
            
            keywords = row.get('keywords')
            if keywords is not None and not isinstance(keywords, list):
                raise ValueError("Keywords must be a list")
            
            entities = row.get('entities')
            if entities is not None and not isinstance(entities, list):
                raise ValueError("Entities must be a list")

            # --- B. Constraint Validation ---
            source = row.get('fonte') or 'Unknown'
            if len(source) > 255:
                raise ValueError(f"Source name too long ({len(source)} > 255)")

            sentiment = row.get('sentiment') or 'Unknown'
            if len(sentiment) > 50:
                raise ValueError(f"Sentiment string too long ({len(sentiment)} > 50)")

            title = row.get('titulo')
            if not title:
                raise ValueError("Missing 'titulo'")
                
            link = row.get('link')

            # --- C. Prepare Valid Record ---
            valid_row = {
                'title': title,
                'link': link,
                'date': dt_obj,
                'source': source,
                'sentiment': sentiment,
                'risk_score': risk_val,
                'keywords': json.dumps(keywords or [], ensure_ascii=False),
                'entities': json.dumps(entities or [], ensure_ascii=False)
            }
            valid_records.append(valid_row)

        except Exception as e:
            # --- D. Prepare Quarantine Record ---
            quarantine_row = {
                'raw_json': json.dumps(row, ensure_ascii=False),
                'error_message': str(e),
                'ingestion_time': datetime.now()
            }
            quarantine_records.append(quarantine_row)

    print(f"Validation Complete: {len(valid_records)} Valid, {len(quarantine_records)} Invalid.")
    return valid_records, quarantine_records

# -------------------------------------------------------------------------
# 3. LOAD (Staging & Quarantine)
# -------------------------------------------------------------------------
def load_to_sql_server(valid_data, quarantine_data, conn_str):
    print("--- Loading Data to SQL Server ---")
    
    try:
        # conn_str já vem formatada do main com o driver correto
        engine = sa.create_engine(conn_str, fast_executemany=True)
        
        with engine.connect() as conn:
            trans = conn.begin()
            try:
                # 1. Reset Staging Tables
                print("Resetting Staging Tables...")
                conn.execute(sa.text("""
                    IF OBJECT_ID('stg_news', 'U') IS NOT NULL DROP TABLE stg_news;
                    IF OBJECT_ID('stg_quarantine', 'U') IS NOT NULL DROP TABLE stg_quarantine;
                    
                    CREATE TABLE stg_news (
                        stg_id INT IDENTITY(1,1) PRIMARY KEY,
                        title NVARCHAR(MAX),
                        link NVARCHAR(MAX),
                        date DATETIME,
                        source NVARCHAR(255),
                        sentiment NVARCHAR(50),
                        risk_score INT,
                        keywords NVARCHAR(MAX),
                        entities NVARCHAR(MAX)
                    );
                    
                    CREATE TABLE stg_quarantine (
                        quarantine_id INT IDENTITY(1,1) PRIMARY KEY,
                        raw_json NVARCHAR(MAX),
                        error_message NVARCHAR(MAX),
                        ingestion_time DATETIME
                    );
                """))

                # 2. Insert Valid Data
                if valid_data:
                    df_stg = pd.DataFrame(valid_data)
                    print(f"Inserting {len(df_stg)} rows into stg_news...")
                    df_stg.to_sql('stg_news', con=conn, if_exists='append', index=False, dtype={
                        'title': sa.types.NVARCHAR(None),
                        'link': sa.types.NVARCHAR(None),
                        'keywords': sa.types.NVARCHAR(None),
                        'entities': sa.types.NVARCHAR(None),
                        'source': sa.types.NVARCHAR(255),
                        'sentiment': sa.types.NVARCHAR(50),
                        'risk_score': sa.types.Integer,
                        'date': sa.types.DateTime
                    })
                
                # 3. Insert Quarantine Data
                if quarantine_data:
                    df_quar = pd.DataFrame(quarantine_data)
                    print(f"Inserting {len(df_quar)} rows into stg_quarantine...")
                    df_quar.to_sql('stg_quarantine', con=conn, if_exists='append', index=False, dtype={
                        'raw_json': sa.types.NVARCHAR(None),
                        'error_message': sa.types.NVARCHAR(None),
                        'ingestion_time': sa.types.DateTime
                    })
                
                trans.commit()
                print("Load Process Completed Successfully.")
                
            except SQLAlchemyError as e:
                trans.rollback()
                print(f"Error occurred during loading: {e}")
                sys.exit(1)

    except Exception as e:
        print(f"Database Connection Error: {e}")
        sys.exit(1)

# -------------------------------------------------------------------------
# Main Execution
# -------------------------------------------------------------------------
if __name__ == "__main__":
    # 1. Parse Arguments
    parser = argparse.ArgumentParser(description="ETL Process for News Data")
    
    parser.add_argument(
        '--file', 
        required=True, 
        help='Full path to the input JSON file'
    )
    parser.add_argument(
        '--conn', 
        required=True, 
        help='Connection parameters (e.g., "Server=.;Database=TAAD;UID=sa;PWD=pass") WITHOUT Driver'
    )
    
    args = parser.parse_args()

    # 2. Build SQLAlchemy URL with Auto-Detected Driver
    try:
        base_conn_str = args.conn
        
        # Só adiciona o driver se o usuário não tiver especificado um manualmente
        if "driver=" not in base_conn_str.lower():
            print("Detecting ODBC Driver...")
            driver = get_best_odbc_driver()
            if not driver:
                print("Error: No suitable ODBC Driver found. Please install ODBC Driver for SQL Server.")
                sys.exit(1)
            print(f"Using detected driver: {driver}")
            # Adiciona o driver no formato exigido: Driver={Nome Do Driver};
            full_conn_str = f"Driver={{{driver}}};{base_conn_str}"
        else:
            full_conn_str = base_conn_str

        # Codifica para URL do SQLAlchemy
        params = urllib.parse.quote_plus(full_conn_str)
        db_url = f"mssql+pyodbc:///?odbc_connect={params}"
        
    except Exception as e:
        print(f"Error building connection string: {e}")
        sys.exit(1)

    # 3. Execute ETL
    raw_data = extract_data(args.file)
    valid_rows, invalid_rows = process_data(raw_data)
    load_to_sql_server(valid_rows, invalid_rows, db_url)