import json
import pandas as pd
import sqlalchemy as sa
from sqlalchemy.exc import SQLAlchemyError
import urllib.parse
import sys

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
        df = pd.json_normalize(data)
        print(f"Loaded {len(df)} records.")
        return df
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        sys.exit(1)

# -------------------------------------------------------------------------
# 2. TRANSFORM (Prepare Data & Identify Issues)
# -------------------------------------------------------------------------
def transform_data(df):
    print("--- Transforming Data ---")
    
    # 2.1 Parse Dates (Coerce errors to NaT to identify them later)
    df['data_publicacao'] = pd.to_datetime(df['data_publicacao'], format='%a, %d %b %Y %H:%M:%S GMT', errors='coerce')
    
    # 2.2 Parse Risk Score (Coerce errors to NaN)
    df['risk_score'] = pd.to_numeric(df['risk_score'], errors='coerce')

    # 2.3 Prepare Keywords (List -> JSON String)
    df['keywords_str'] = df['keywords'].apply(lambda x: json.dumps(x, ensure_ascii=False) if isinstance(x, list) else '[]')

    # 2.4 Normalize Sentiment (for Staging)
    # Note: We are NOT truncating here, we keep original to check length later
    sentiment_map = {
        'positivo': 1, 'negativo': -1, 'neutro': 0,
        'neutral': 0, 'positive': 1, 'negative': -1
    }
    df['sentiment_norm'] = df['sentiment'].astype(str).str.lower().str.strip()
    df['polarity'] = df['sentiment_norm'].map(sentiment_map).fillna(0)

    # 2.5 Enrich with Time Dimensions (Derived from Date)
    df['year'] = df['data_publicacao'].dt.year
    df['month'] = df['data_publicacao'].dt.month
    df['day'] = df['data_publicacao'].dt.day
    df['weekday'] = df['data_publicacao'].dt.day_name()
    
    meses_pt = {
        1: "Janeiro", 2: "Fevereiro", 3: "Março", 4: "Abril", 5: "Maio", 6: "Junho",
        7: "Julho", 8: "Agosto", 9: "Setembro", 10: "Outubro", 11: "Novembro", 12: "Dezembro"
    }
    df['month_name'] = df['month'].map(meses_pt)
    
    # 2.6 Source Country Default
    df['source_country'] = 'Portugal'
    df['fonte'] = df['fonte'].fillna('Desconhecido')

    return df

# -------------------------------------------------------------------------
# 3. LOAD (Split & Send to Staging or Quarantine)
# -------------------------------------------------------------------------
def load_to_sql_server(df, conn_str):
    print("--- Loading Data ---")
    
    # ---------------------------------------------------------
    # A. Define Validation Logic
    # ---------------------------------------------------------
    # Rule 1: Date must exist
    mask_date = df['data_publicacao'].notna()
    # Rule 2: Risk Score must be numeric
    mask_score = df['risk_score'].notna()
    # Rule 3: Sentiment text length <= 50 chars (Database constraint)
    mask_sentiment = df['sentiment'].astype(str).str.len() <= 50

    # Combine rules: Valid if ALL are true
    is_valid = mask_date & mask_score & mask_sentiment

    # ---------------------------------------------------------
    # B. Split DataFrames
    # ---------------------------------------------------------
    df_valid = df[is_valid].copy()
    df_quarantine = df[~is_valid].copy()

    # ---------------------------------------------------------
    # C. Prepare Quarantine Data (Add Reason)
    # ---------------------------------------------------------
    if not df_quarantine.empty:
        def get_reason(row):
            reasons = []
            if pd.isna(row['data_publicacao']): reasons.append("Invalid Date")
            if pd.isna(row['risk_score']): reasons.append("Invalid Risk Score")
            if len(str(row['sentiment'])) > 50: reasons.append("Sentiment too long")
            return "; ".join(reasons)
        
        df_quarantine['quarantine_reason'] = df_quarantine.apply(get_reason, axis=1)
        # Add timestamp
        df_quarantine['loaded_at'] = pd.Timestamp.now()

    print(f"Total Records: {len(df)}")
    print(f" -> Valid (to Staging): {len(df_valid)}")
    print(f" -> Invalid (to Quarantine): {len(df_quarantine)}")

    # ---------------------------------------------------------
    # D. Write to SQL Server
    # ---------------------------------------------------------
    engine = sa.create_engine(conn_str, fast_executemany=True)

    with engine.begin() as conn:
        # 1. Load Valid Data -> stg_news_feed
        if not df_valid.empty:
            # Select only columns needed for Staging
            cols_staging = [
                'titulo', 'link', 'data_publicacao', 'fonte', 
                'sentiment', 'risk_score', 'keywords_str', 
                'year', 'month', 'day', 'weekday', 'month_name', 'polarity', 'source_country'
            ]
            df_valid[cols_staging].to_sql(
                'stg_news_feed', 
                con=conn, 
                if_exists='replace', # Wipe and reload staging
                index=False,
                dtype={
                    'keywords_str': sa.types.NVARCHAR(None),
                    'sentiment': sa.types.NVARCHAR(50), 
                    'titulo': sa.types.NVARCHAR(None),
                    'link': sa.types.NVARCHAR(None)
                }
            )
            print("Successfully wrote to 'stg_news_feed'.")

        # 2. Load Invalid Data -> quarantine_news
        if not df_quarantine.empty:
            # Select relevant columns for debugging
            cols_quarantine = [
                'titulo', 'link', 'data_publicacao', 'fonte', 
                'sentiment', 'risk_score', 'quarantine_reason', 'loaded_at'
            ]
            
            # Use 'append' so we keep history of bad data (optional, could be 'replace')
            df_quarantine[cols_quarantine].to_sql(
                'quarantine_news', 
                con=conn, 
                if_exists='append', 
                index=False,
                dtype={
                    'sentiment': sa.types.NVARCHAR(None), # Allow long text here
                    'quarantine_reason': sa.types.NVARCHAR(255)
                }
            )
            print("Successfully wrote to 'quarantine_news'.")

# -------------------------------------------------------------------------
# 4. Database Setup (Ensure Tables Exist)
# -------------------------------------------------------------------------
def create_schema(conn_str):
    """Ensures Staging and Quarantine tables exist."""
    engine = sa.create_engine(conn_str)
    with engine.connect() as conn:
        conn.execute(sa.text("""
            -- 1. Quarantine Table
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='quarantine_news' and xtype='U')
            CREATE TABLE quarantine_news (
                q_id INT IDENTITY(1,1) PRIMARY KEY,
                titulo NVARCHAR(MAX),
                link NVARCHAR(MAX),
                data_publicacao DATETIME, -- Can be NULL
                fonte NVARCHAR(255),
                sentiment NVARCHAR(MAX),  -- Max length to catch overflow errors
                risk_score FLOAT,         -- Can be NULL
                quarantine_reason NVARCHAR(255),
                loaded_at DATETIME DEFAULT GETDATE()
            );

            -- 2. Staging Table (Implicitly created by Pandas 'to_sql', but good to define if needed)
            -- We don't strictly need CREATE TABLE for staging if using if_exists='replace' in Pandas,
            -- but this ensures the DB is reachable.
        """))
        conn.commit()
        print("Schema check completed.")

# -------------------------------------------------------------------------
# Main Execution
# -------------------------------------------------------------------------
if __name__ == "__main__":
    # 1. Initialize Schema
    create_schema(DB_CONNECTION_STR)
    
    # 2. Extract
    df_raw = extract_data(INPUT_FILE)
    
    # 3. Transform
    df_transformed = transform_data(df_raw)
    
    # 4. Load (Split & Store)
    load_to_sql_server(df_transformed, DB_CONNECTION_STR)