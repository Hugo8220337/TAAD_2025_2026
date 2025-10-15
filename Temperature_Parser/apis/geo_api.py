import requests

def get_lat_lon(city, country=None):
    # Busca coordenadas pelo nome da cidade (e país, se fornecido)
    url = "https://geocoding-api.open-meteo.com/v1/search"
    params = {"name": city}
    if country:
        params["country"] = country
    response = requests.get(url, params=params)
    results = response.json().get("results")
    if not results:
        raise Exception(f"Local '{city}' não encontrado.")
    lat = results[0]["latitude"]
    lon = results[0]["longitude"]
    return lat, lon