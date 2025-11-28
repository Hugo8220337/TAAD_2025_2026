import logging
import argparse
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

def _execute_sql_file(cnxn, sql_file):
    with open(sql_file, 'r') as file:
        sql_script = file.read()
        cursor = cnxn.cursor()
        cursor.execute(sql_script)
        cnxn.commit()
        cursor.close()

def _insert_csv_to_table(cnxn, csv_file, table_name):
    df = pd.read_csv(csv_file)
    cursor = cnxn.cursor()
    
    # Generate insert query
    columns = ', '.join(df.columns)
    placeholders = ', '.join(['?'] * len(df.columns))
    insert_query = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"
    
    # Insert each row
    for index, row in df.iterrows():
        cursor.execute(insert_query, tuple(row))
    
    cnxn.commit()
    cursor.close()

def run(
        data_dir,
        sql_dir,
        db_connection_string
):
    """Run the SQL Server Inserter process"""
    logging.info("Starting SQL Server Inserter process")
    
    # Connect to the database
    cnxn = pypyodbc.connect(db_connection_string)

    # Execute each SQL file to create tables
    sql_files = _get_sql_files(sql_dir)
    for sql_file in sql_files:
        logging.info(f"Executing SQL file: {sql_file}")
        _execute_sql_file(cnxn, sql_file)

    
    # Insert CSV files into corresponding tables
    for root, _, files in os.walk(data_dir):
        for file in files:
            if file.endswith('.csv'):
                csv_file = os.path.join(root, file)
                table_name = os.path.splitext(file)[0]  # Assuming table name is the same as CSV file name without extension
                logging.info(f"Inserting data from {csv_file} into table {table_name}")
                _insert_csv_to_table(cnxn, csv_file, table_name)

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
        default="Driver={ODBC Driver 17 for SQL Server};Server=localhost,1433;Database=TAAD_DB;UID=sa;PWD=#password123sdJwnwlk;",
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