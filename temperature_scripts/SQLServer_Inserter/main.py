import logging
import argparse
import re
import pyodbc
import pypyodbc 
import pandas as pd
import os

def _get_sql_files(sql_dir):
    sql_files = []
    for root, _, files in os.walk(sql_dir):
        for file in files:
            if file.endswith('.sql'):
                sql_files.append(os.path.join(root, file))
    return sql_files

def get_best_odbc_driver(prefer = ("ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server", "SQL Server Native Client 11.0", "SQL Server")):
    available = [d for d in pyodbc.drivers()]
    for pref in prefer:
        for a in available:
            if pref.lower() in a.lower():
                return a
    return available[0] if available else None

def _execute_sql_file(cnxn, sql_file):
    with open(sql_file, 'r', encoding='utf-8') as file:
        sql_script = file.read()
    # split batches on lines containing only GO (case-insensitive)
    batches = [b.strip() for b in re.split(r'(?im)^[ \t]*GO[ \t]*\r?$' , sql_script) if b.strip()]
    cursor = cnxn.cursor()
    for batch in batches:
        try:
            cursor.execute(batch)
            cnxn.commit()
        except pypyodbc.ProgrammingError as e:
            msg = str(e)
            # ignore "already exists" on create table
            if "There is already an object named" in msg:
                logging.info(f"Ignoring existing object error for {sql_file}: {msg}")
                continue
            else:
                cursor.close()
                raise
    cursor.close()

def _get_table_columns(cnxn, table_name):
    # suporta formats: "schema.table" ou "table"
    schema = "dbo"
    table = table_name
    if "." in table_name:
        parts = table_name.split(".", 1)
        schema, table = parts[0], parts[1]
    q = """
    SELECT COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
    """
    cur = cnxn.cursor()
    cur.execute(q, (schema, table))
    cols = [row[0] for row in cur.fetchall()]
    cur.close()
    return cols

def _insert_csv_to_table(cnxn, csv_file, table_name):
    # read all columns as string to avoid cast issues
    df = pd.read_csv(csv_file, dtype=str, sep="|").fillna('')
    if df.empty:
        logging.info(f"No rows in {csv_file}, skipping")
        return

    try:
        table_columns = _get_table_columns(cnxn, table_name)
    except Exception as e:
        logging.error(f"Could not retrieve columns for table {table_name}: {e}")
        return

    csv_cols = list(df.columns)
    cols_to_insert = [c for c in csv_cols if c in table_columns]

    if not cols_to_insert:
        logging.error(f"No matching columns between CSV and table {table_name}. CSV cols: {csv_cols[:10]}...")
        return

    ignored = [c for c in csv_cols if c not in cols_to_insert]
    if ignored:
        logging.info(f"Ignoring CSV columns not present in {table_name}: {ignored[:10]}")

    cursor = cnxn.cursor()
    columns_br = ', '.join([f'[{c}]' for c in cols_to_insert])
    placeholders = ', '.join(['?'] * len(cols_to_insert))
    insert_query = f"INSERT INTO [{table_name}] ({columns_br}) VALUES ({placeholders})"

    inserted_count = 0
    failed_rows = []
    for index, row in df.iterrows():
        values = tuple((row[c].strip() if isinstance(row[c], str) else row[c]) for c in cols_to_insert)
        try:
            cursor.execute(insert_query, values)
            inserted_count += 1
        except Exception as e:
            err_text = str(e)
            logging.debug(f"Row {index} error details: {err_text}")
            failed_rows.append((index, values, err_text))
            # continue with next row

    cnxn.commit()
    cursor.close()

    logging.info(f"Inserted {inserted_count} rows from {os.path.basename(csv_file)} into {table_name}")
    if failed_rows:
        # Save failed rows and their errors into a single .failed.log file (tab-separated)
        errlog = os.path.splitext(csv_file)[0] + '.failed.log'
        with open(errlog, 'w', encoding='utf-8') as fh:
            # header: columns + ERROR
            fh.write('\t'.join(cols_to_insert) + '\tERROR\n')
            for idx, vals, err in failed_rows:
                row_text = '\t'.join('' if v is None else str(v) for v in vals)
                fh.write(f"{row_text}\t{err}\n")
        logging.info(f"{len(failed_rows)} rows failed and were saved to {errlog}")

def run(
        data_dir,
        sql_dir,
        db_connection_string
):
    """Run the SQL Server Inserter process"""
    driver = get_best_odbc_driver()
    if driver:
        db_connection_string = "Driver={" + driver + "};" + db_connection_string
        logging.info(f"Using ODBC Driver: {driver}")
        logging.info(f"Database connection string: {db_connection_string}")
    else:
        logging.error("No ODBC Driver for SQL Server found. Please install one.")
        raise SystemExit(1)
    
    logging.info("Starting SQL Server Inserter process")
    
    # Connect to the database
    try:
        cnxn = pypyodbc.connect(db_connection_string, timeout=5)
        logging.info("Successfully connected to SQL Server")
    except pypyodbc.DatabaseError as e:
        logging.error("Falha ao conectar ao SQL Server. Verifique credenciais, modo de autenticação e nome/porta da instância.")
        logging.error(f"Detalhe do erro: {e}")
        raise SystemExit(1)

    # Execute each SQL file to create tables
    sql_files = _get_sql_files(sql_dir)
    for sql_file in sql_files:
        logging.info(f"Executing SQL file: {sql_file}")
        try:
            _execute_sql_file(cnxn, sql_file)
        except Exception as e:
            logging.error(f"Failed to execute SQL file {sql_file}: {e}")

    
    # Insert CSV files into corresponding tables
    for root, _, files in os.walk(data_dir):
        for file in files:
            if file.endswith('.csv'):
                csv_file = os.path.join(root, file)
                table_name = os.path.splitext(file)[0]
                # Map year filenames (e.g. "2025.csv") to the main table
                if table_name.isdigit():
                    table_name = "dsa_meteorology"
                logging.info(f"Inserting data from {csv_file} into table {table_name}")
                try:
                    _insert_csv_to_table(cnxn, csv_file, table_name)
                except Exception as e:
                    logging.error(f"Error inserting {csv_file} -> {e}")

    # Close the database connection
    cnxn.close()
    logging.info("SQL Server Inserter process completed")
    


def main():
    """Main function with argument parsing for SQL Server Inserter"""
    parser = argparse.ArgumentParser(description='Insert data into SQL Server database from CSV files')
    
    parser.add_argument(
        '--data_dir', '-i',
        type=str,
        required=False,
        default='./data',
        help='Input directory containing CSV files (default: data)'
    )

    parser.add_argument(
        '--sql_dir', '-s',
        type=str,
        required=False,
        default='./sql',
        help='Directory containing SQL files'
    )
    
    parser.add_argument(
        '--db_connection', '-d',
        type=str,
        required=True,
        default="Server=localhost,1433;Database=TAAD_DB;UID=sa;PWD=#password123sdJwnwlk;",
        help='Database connection string'
    )
    
    
    args = parser.parse_args()
    
    # Configure logging
    logging.basicConfig(
        level=getattr(logging, "INFO"),
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    
    # Run the insertion process
    run(
        data_dir=args.data_dir,
        sql_dir=args.sql_dir,
        db_connection_string=args.db_connection,
    )    

if __name__ == "__main__":
    main()