import json
import pandas as pd
import sqlalchemy as sa
from sqlalchemy.exc import SQLAlchemyError
from datetime import datetime
import urllib.parse

# -------------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------------
# Update connection string for your SQL Server environment
# Driver might be 'ODBC Driver 17 for SQL Server' or similar
connection_string = 'DRIVER={ODBC Driver 17 for SQL Server};Server=.;Database=TAAD;Trusted_Connection=yes;'

# 2. Encode it for SQLAlchemy
params = urllib.parse.quote_plus(connection_string)

# 3. Create the Engine URL
DB_CONNECTION_STR = f"mssql+pyodbc:///?odbc_connect={params}"

# File paths
INPUT_FILE = 'News/output.json'

# -------------------------------------------------------------------------
# 1. EXTRACT
# -------------------------------------------------------------------------
def extract_data(file_path):
    print("--- Extracting Data ---")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    df = pd.json_normalize(data)
    print(f"Loaded {len(df)} records.")
    return df

# -------------------------------------------------------------------------
# 2. TRANSFORM
# -------------------------------------------------------------------------
def transform_data(df):
    print("--- Transforming Data ---")
    
    # 2.1 Parse Dates
    df['data_publicacao'] = pd.to_datetime(df['data_publicacao'], format='%a, %d %b %Y %H:%M:%S GMT', errors='coerce')
    df = df.dropna(subset=['data_publicacao'])

    df['risk_score'] = pd.to_numeric(df['risk_score'], errors='coerce').fillna(0.0)

    # 2.2 Prepare Keywords
    df['keywords_str'] = df['keywords'].apply(lambda x: json.dumps(x, ensure_ascii=False) if isinstance(x, list) else '[]')
    

    # 2.3 Standardize Sentiment (UPDATED LOGIC)
    # ---------------------------------------------------------
    # Rule: If sentiment is too long (likely a description), categorize as 'Misto' or 'Outro'
    def clean_sentiment(text):
        if not isinstance(text, str):
            return "Desconhecido"
        text = text.strip()
        # If it's one of the standard simple ones, keep it
        if text.lower() in ['positivo', 'negativo', 'neutro', 'positive', 'negative', 'neutral']:
            return text.title() # Return as Title Case (e.g., "Positivo")
        # If it starts with "misto", just group it as "Misto"
        if text.lower().startswith('misto'):
            return "Misto"
        # If it's still too long, truncate or categorize
        if len(text) > 50:
            return "Outro (Complexo)"
        return text

    df['sentiment'] = df['sentiment'].apply(clean_sentiment)
    # ---------------------------------------------------------

    sentiment_map = {
        'Positivo': 1, 'Positive': 1,
        'Negativo': -1, 'Negative': -1,
        'Neutro': 0, 'Neutral': 0,
        'Misto': 0, 'Outro (Complexo)': 0
    }
    
    df['sentiment_norm'] = df['sentiment'] # Already cleaned above
    df['polarity'] = df['sentiment_norm'].map(sentiment_map).fillna(0)

    # 2.4 Prepare Dimension Attributes
    df['date_key'] = df['data_publicacao'].dt.date
    df['year'] = df['data_publicacao'].dt.year
    df['month'] = df['data_publicacao'].dt.month
    
    meses_pt = {
        1: "Janeiro", 2: "Fevereiro", 3: "Março", 4: "Abril", 5: "Maio", 6: "Junho",
        7: "Julho", 8: "Agosto", 9: "Setembro", 10: "Outubro", 11: "Novembro", 12: "Dezembro"
    }
    df['month_name'] = df['month'].map(meses_pt)
    df['day'] = df['data_publicacao'].dt.day
    df['weekday'] = df['data_publicacao'].dt.day_name()

    df['source_country'] = 'Portugal' 
    df['fonte'] = df['fonte'].fillna('Desconhecido')

    return df

# -------------------------------------------------------------------------
# 3. LOAD (Staging & DW)
# -------------------------------------------------------------------------
def load_to_sql_server(df, conn_str):
    print("--- Loading Data to SQL Server ---")
    
    engine = sa.create_engine(conn_str, fast_executemany=True)
    
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            # ----------------------------------------
            # A. Staging Area
            # ----------------------------------------
            print("Loading Staging Table...")
            # We dump the transformed dataframe into a raw staging table
            df_staging = df[[
                'titulo', 'link', 'data_publicacao', 'fonte', 
                'sentiment', 'risk_score', 'keywords_str', 
                'year', 'month', 'day', 'weekday', 'month_name', 'polarity', 'source_country'
            ]].copy()
            
            df_staging.to_sql('stg_news_feed', con=conn, if_exists='replace', index=False, dtype={
                'keywords_str': sa.types.NVARCHAR(None) # Max length
            })
            
            # ----------------------------------------
            # B. Dimension: dim_date
            # ----------------------------------------
            print("Processing dim_date...")
            # Logic: Insert dates that don't exist yet
            # In a real scenario, you might pre-populate this table for 10-20 years
            
            # Using T-SQL MERGE or distinct insert logic
            sql_dim_date = """
            INSERT INTO dim_date (date, year, month, month_name, day, weekday)
            SELECT DISTINCT 
                CAST(data_publicacao AS DATE), year, month, month_name, day, weekday
            FROM stg_news_feed
            WHERE CAST(data_publicacao AS DATE) NOT IN (SELECT date FROM dim_date);
            """
            conn.execute(sa.text(sql_dim_date))

            # ----------------------------------------
            # C. Dimension: dim_source
            # ----------------------------------------
            print("Processing dim_source...")
            sql_dim_source = """
            INSERT INTO dim_source (source_name, country)
            SELECT DISTINCT fonte, source_country
            FROM stg_news_feed
            WHERE fonte NOT IN (SELECT source_name FROM dim_source);
            """
            conn.execute(sa.text(sql_dim_source))

            # ----------------------------------------
            # D. Dimension: dim_sentiment
            # ----------------------------------------
            print("Processing dim_sentiment...")
            sql_dim_sentiment = """
            INSERT INTO dim_sentiment (sentiment, polarity)
            SELECT DISTINCT sentiment, polarity
            FROM stg_news_feed
            WHERE sentiment NOT IN (SELECT sentiment FROM dim_sentiment);
            """
            conn.execute(sa.text(sql_dim_sentiment))

            # ----------------------------------------
            # E. Fact Table: fact_news
            # ----------------------------------------
            print("Processing fact_news...")
            # We join Staging with Dimensions to get Surrogate Keys (IDs)
            sql_fact = """
            INSERT INTO fact_news (title, link, risk_score, keywords, date_id, source_id, sentiment_id)
            SELECT 
                stg.titulo,
                stg.link,
                stg.risk_score,
                stg.keywords_str,
                dd.date_id,
                ds.source_id,
                dsem.sentiment_id
            FROM stg_news_feed stg
            JOIN dim_date dd ON CAST(stg.data_publicacao AS DATE) = dd.date
            JOIN dim_source ds ON stg.fonte = ds.source_name
            JOIN dim_sentiment dsem ON stg.sentiment = dsem.sentiment
            -- Prevent duplicates based on link
            WHERE stg.link NOT IN (SELECT link FROM fact_news);
            """
            conn.execute(sa.text(sql_fact))
            
            trans.commit()
            print("ETL Process Completed Successfully.")
            
        except SQLAlchemyError as e:
            trans.rollback()
            print(f"Error occurred: {e}")
            raise

# -------------------------------------------------------------------------
# 4. Database Setup (DDL) - Helper function to init DB
# -------------------------------------------------------------------------
def create_schema(conn_str):
    """Creates tables based on news.dbml specification if they don't exist"""
    engine = sa.create_engine(conn_str)
    with engine.connect() as conn:
        conn.execute(sa.text("""
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='dim_date' and xtype='U')
            CREATE TABLE dim_date (
                date_id INT IDENTITY(1,1) PRIMARY KEY,
                date DATE UNIQUE,
                year INT,
                month INT,
                month_name NVARCHAR(20),
                day INT,
                weekday NVARCHAR(20)
            );

            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='dim_source' and xtype='U')
            CREATE TABLE dim_source (
                source_id INT IDENTITY(1,1) PRIMARY KEY,
                source_name NVARCHAR(255) UNIQUE,
                country NVARCHAR(100)
            );

            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='dim_sentiment' and xtype='U')
            CREATE TABLE dim_sentiment (
                sentiment_id INT IDENTITY(1,1) PRIMARY KEY,
                sentiment NVARCHAR(50) UNIQUE,
                polarity INT
            );

            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='fact_news' and xtype='U')
            CREATE TABLE fact_news (
                news_id INT IDENTITY(1,1) PRIMARY KEY,
                title NVARCHAR(MAX),
                link NVARCHAR(MAX), -- In production, maybe hash this for indexing
                date_id INT FOREIGN KEY REFERENCES dim_date(date_id),
                source_id INT FOREIGN KEY REFERENCES dim_source(source_id),
                sentiment_id INT FOREIGN KEY REFERENCES dim_sentiment(sentiment_id),
                risk_score float,
                keywords NVARCHAR(MAX) -- Storing array as JSON string
            );
        """))
        conn.commit()
        print("Schema ensured.")

# -------------------------------------------------------------------------
# Main Execution
# -------------------------------------------------------------------------
if __name__ == "__main__":
    # 1. Initialize DB Schema (Run once)
    create_schema(DB_CONNECTION_STR)
    
    # 2. Extract
    df_raw = extract_data(INPUT_FILE)
    
    # 3. Transform
    df_transformed = transform_data(df_raw)
    
    # 4. Load
    load_to_sql_server(df_transformed, DB_CONNECTION_STR)
    
    # For demonstration, let's preview the transformed data structure
    print("\nPreview of Transformed Data for Staging:")
    print(df_transformed[['titulo', 'year', 'month_name', 'polarity', 'risk_score']].head())