---

# Dicionário de Dados — Ficheiros de Meteorologia (`meteorology_*.csv`)

Este documento descreve os atributos presentes nos ficheiros de meteorologia diária associados a cada incêndio.

| Campo | Descrição | Tipo | Exemplo | Notas |
| :--- | :--- | :--- | :--- | :--- |
| `incident_id` | Identificador único do incêndio, correspondente ao `id` do ICNF. | string | `AG120357` | Chave para ligar aos dados principais do incêndio. |
| `source_file` | Ficheiro de origem dos dados do incêndio. | string | `2020.csv` | Indica o ano do dataset original. |
| `date` | Data do registo meteorológico. | date | `2020-05-03` | Formato: YYYY-MM-DD. |
| `lat` | Latitude do ponto de referência do incêndio. | float | `37.130277` | Coordenadas em graus decimais (WGS84). |
| `lon` | Longitude do ponto de referência do incêndio. | float | `-8.883888` | Coordenadas em graus decimais (WGS84). |
| `temp_max` | Temperatura máxima diária. | float | `25.9` | Unidade: Graus Celsius (°C). |
| `temp_min` | Temperatura mínima diária. | float | `14.6` | Unidade: Graus Celsius (°C). |
| `rh_max` | Humidade relativa máxima diária. | integer | `87` | Unidade: Percentagem (%). |
| `rh_min` | Humidade relativa mínima diária. | integer | `45` | Unidade: Percentagem (%). |
| `precip_sum` | Soma total da precipitação diária. | float | `0.0` | Unidade: Milímetros (mm). |
| `rain_sum` | Soma total da chuva diária. | float | `0.0` | Unidade: Milímetros (mm). |
| `precip_hours`| Número de horas com precipitação no dia. | float | `0.0` | Unidade: Horas. |
| `wind_max` | Velocidade máxima do vento. | float | `27.7` | Unidade: Provavelmente km/h. |
| `gust_max` | Rajada máxima de vento. | float | `54.4` | Unidade: Provavelmente km/h. |
| `wind_dir` | Direção dominante do vento. | integer | `112` | Unidade: Graus (0-360°). |
| `radiation` | Radiação solar total diária. | float | `26.96` | Unidade: Provavelmente Megajoules por metro quadrado (MJ/m²). |
| `sunshine` | Duração total da luz solar. | float | `46527.24` | Unidade: Provavelmente segundos (s). |
| `et0` | Evapotranspiração de referência (FAO-56 Penman-Monteith). | float | `5.53` | Unidade: Milímetros (mm). |
