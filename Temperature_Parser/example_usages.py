import pandas as pd
from apis.geo_api import get_lat_lon
from apis.open_meteo_api import get_temperature
from utils.file_utils import get_data_files
    

if __name__ == "__main__":
    # Get list of csv files in the 'data' directory
    files = get_data_files("data", pattern="*.csv", recursive=False)

    df = pd.read_csv(files[0], sep="|")  # Example of reading the first CSV file
    print(df.head())  # Display the first few rows of the dataframe

    # Exemplo para buscar coordenadas de uma cidade
    cidade = "Lisboa"
    pais = "PT"
    lat, lon = get_lat_lon(cidade, pais)
    print("Coordenadas:", lat, lon)


    # Exemplo para buscar temperatura diária durante um mês
    # temperatura = get_temperature(lat, lon, "2023-08-01", "2023-08-31")
    # print(temperatura)

