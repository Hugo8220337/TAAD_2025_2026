import logging
import time
import requests

def get_temperature(lat, lon, start_date, end_date, max_retries=3, retry_delay=1):
    """
    Search for daily maximum and minimum temperature between specific dates.
    
    Args:
        lat: latitude
        lon: longitude
        start_date: initial date (YYYY-MM-DD)
        end_date: final date (YYYY-MM-DD)
        max_retries: maximum number of attempts (default: 3)
        retry_delay: time to wait between attempts in seconds (default: 1)

    Returns:
        dict: daily weather data

    Raises:
        Exception: if all attempts fail
    """
    url = "https://archive-api.open-meteo.com/v1/archive"
    daily_vars = [
        "temperature_2m_max","temperature_2m_min","temperature_2m_mean",
        "relative_humidity_2m_max","relative_humidity_2m_min","relative_humidity_2m_mean",
        "precipitation_sum","rain_sum","precipitation_hours",
        "windspeed_10m_max","windspeed_10m_mean","windgusts_10m_max","winddirection_10m_dominant",
        "shortwave_radiation_sum","sunshine_duration",
        "et0_fao_evapotranspiration",
        "pressure_msl_mean",
        "cloudcover_mean"
    ]
    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": start_date,
        "end_date": end_date,
        "daily": ",".join(daily_vars),
        "timezone": "auto",
        "temperature_unit": "celsius",
        "windspeed_unit": "kmh",
        "precipitation_unit": "mm"
    }
    
    last_exception = None
    
    for attempt in range(max_retries):
        try:
            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()  # Levanta exceção para códigos de erro HTTP
            data = response.json()
            
            # Verifica se a resposta contém os dados esperados
            if "daily" not in data:
                raise ValueError(f"API response missing 'daily' key: {data}")
                
            return data["daily"]

        except (requests.exceptions.RequestException, ValueError, KeyError) as e:
            last_exception = e
            
            if attempt < max_retries - 1:  # Não é a última tentativa
                logging.warning(f"API attempt {attempt + 1}/{max_retries} failed for ({lat},{lon}): {e}")
                time.sleep(retry_delay * (attempt + 1))  # Backoff exponencial
            else:
                logging.error(f"All {max_retries} API attempts failed for ({lat},{lon})")
    
    # Se chegou aqui, todas as tentativas falharam
    raise last_exception