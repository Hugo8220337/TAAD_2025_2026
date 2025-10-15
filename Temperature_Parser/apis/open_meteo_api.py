import requests

def get_temperature(lat, lon, start_date, end_date):
    # Busca temperatura diária máxima e mínima entre datas específicas
    url = "https://archive-api.open-meteo.com/v1/archive"
    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": start_date,
        "end_date": end_date,
        "daily": "temperature_2m_max,temperature_2m_min",
        "timezone": "auto"
    }
    response = requests.get(url, params=params)
    data = response.json()
    return data["daily"]