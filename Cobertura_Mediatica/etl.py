import json
import pandas as pd
import sqlalchemy as sa
from sqlalchemy.exc import SQLAlchemyError
from datetime import datetime
import urllib.parse

# -------------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------------
connection_string = 'DRIVER={ODBC Driver 17 for SQL Server};Server=.;Database=TAAD;Trusted_Connection=yes;'
params = urllib.parse.quote_plus(connection_string)
DB_CONNECTION_STR = f"mssql+pyodbc:///?odbc_connect={params}"

INPUT_FILE = 'News/output.json'

# -------------------------------------------------------------------------
# 1. EXTRACT
# -------------------------------------------------------------------------
def extract_data(file_path):
    print("--- Extracting Data ---")
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"Loaded {len(data)} raw records.")
        return data
    except Exception as e:
        print(f"Error reading file: {e}")
        return []

# -------------------------------------------------------------------------
# 2. VALIDATE AND SEGREGATE
# -------------------------------------------------------------------------
def process_data(data):
    """
    Validates data against the schema.
    Rows failing validation (types, length limits) are sent to Quarantine.
    """
    print("--- Validating Data ---")
    valid_records = []
    quarantine_records = []
    
    for row in data:
        try:
            # --- A. Type Validation ---
            
            # 1. Date (Must be present and parsable)
            raw_date = row.get('data_publicacao')
            if not raw_date:
                raise ValueError("Missing 'data_publicacao'")
            try:
                # Format: 'Fri, 15 Dec 2023 10:00:00 GMT'
                dt_obj = datetime.strptime(raw_date, '%a, %d %b %Y %H:%M:%S GMT')
            except ValueError:
                raise ValueError(f"Invalid date format: {raw_date}")

            # 2. Risk Score (Must be valid Integer)
            raw_risk = row.get('risk_score')
            risk_val = 0
            if raw_risk is not None:
                try:
                    risk_val = int(float(raw_risk))
                except (ValueError, TypeError):
                    raise ValueError(f"Invalid risk_score type: {raw_risk}")
            
            # 3. Lists (Must be lists)
            keywords = row.get('keywords')
            if keywords is not None and not isinstance(keywords, list):
                raise ValueError("Keywords must be a list")
            
            entities = row.get('entities')
            if entities is not None and not isinstance(entities, list):
                raise ValueError("Entities must be a list")

            # --- B. Constraint/Length Validation ---
            # We validate string lengths here to prevent SQL Truncation errors later.
            
            source = row.get('fonte') or 'Unknown'
            if len(source) > 255:
                raise ValueError(f"Source name too long ({len(source)} > 255)")

            sentiment = row.get('sentiment') or 'Unknown'
            if len(sentiment) > 50:
                raise ValueError(f"Sentiment string too long ({len(sentiment)} > 50)")

            # Title and Link are allowed to be MAX, but let's sanitize if needed.
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
            # Captures the raw data and the specific error reason
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
    
    engine = sa.create_engine(conn_str, fast_executemany=True)
    
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            # 1. Reset Staging Tables (Drop & Recreate)
            # This ensures the schema (lengths/types) is always correct for the current run
            # and prevents "String data, right truncation" errors from old table definitions.
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
                # We specify dtypes explicitly to ensure NVARCHAR(MAX) is used where needed
                df_stg.to_sql('stg_news', con=conn, if_exists='append', index=False, dtype={
                    'title': sa.types.NVARCHAR(None),    # MAX
                    'link': sa.types.NVARCHAR(None),     # MAX
                    'keywords': sa.types.NVARCHAR(None), # MAX
                    'entities': sa.types.NVARCHAR(None), # MAX
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
                    'raw_json': sa.types.NVARCHAR(None),      # MAX - Ensures no truncation for invalid data
                    'error_message': sa.types.NVARCHAR(None), # MAX
                    'ingestion_time': sa.types.DateTime
                })
            
            trans.commit()
            print("Load Process Completed Successfully.")
            
        except SQLAlchemyError as e:
            trans.rollback()
            print(f"Error occurred during loading: {e}")
            raise

# -------------------------------------------------------------------------
# Main Execution
# -------------------------------------------------------------------------
if __name__ == "__main__":
    # 1. Extract
    raw_data = extract_data(INPUT_FILE)
    
    # 2. Validate / Segregate
    valid_rows, invalid_rows = process_data(raw_data)
    
    # 3. Load (includes Table Creation)
    load_to_sql_server(valid_rows, invalid_rows, DB_CONNECTION_STR)