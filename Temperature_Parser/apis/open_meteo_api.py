import requests

def get_temperature(lat, lon, start_date, end_date):
    # Busca temperatura diária máxima e mínima entre datas específicas
    url = "https://archive-api.open-meteo.com/v1/archive"
    daily_vars = [
        "temperature_2m_max","temperature_2m_min",
        "relative_humidity_2m_max","relative_humidity_2m_min",
        "precipitation_sum","rain_sum","precipitation_hours",
        "windspeed_10m_max","windgusts_10m_max","winddirection_10m_dominant",
        "shortwave_radiation_sum","sunshine_duration",
        "et0_fao_evapotranspiration"
    ]
    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": start_date,
        "end_date": end_date,
        "daily": ",".join(daily_vars),
        "timezone": "auto",
        "temperature_unit": "celsius",
        "windspeed_unit": "kmh",        # ou m/s
        "precipitation_unit": "mm"
    }
    response = requests.get(url, params=params)
    data = response.json()
    return data["daily"]