/*
    Script: populate_fact_meteorology.sql
    Executar na conexão: [DSA.TAAD]
    Objetivo: Ler da Staging Local, cruzar com Localização e Dias, escrever na Facto Remota (DW).
*/

-- 1. CTE para garantir unicidade (Um registo meteorológico por Incêndio/Dia)
WITH UniqueMeteo AS (
    SELECT 
        *,
        -- Particiona por Incidente e Data para evitar duplicados
        ROW_NUMBER() OVER(PARTITION BY incident_id, [date] ORDER BY (SELECT NULL)) as rn
    FROM [dbo].[dsa_meteorology]
)
INSERT INTO [DW.TAAD].[dbo].[fact_daily_meteorology] (
    -- Chaves
    day_id,
    location_id,

    -- Temperatura
    temp_max,
    temp_min,
    temp_mean,

    -- Humidade
    rh_max,
    rh_min,
    rh_mean,

    -- Precipitação
    precip_sum,
    rain_sum,
    precip_hours,

    -- Vento
    wind_max,
    gust_max,
    wind_dir,
    wind_speed_mean,

    -- Radiação
    radiation,
    sunshine,
    shortwave_radiation,

    -- Evapotranspiração
    et0,

    -- Outros (NULLs conforme original)
    pressure_msl,
    cloud_cover,

    -- Flags Calculadas
    is_dry_day,
    is_high_wind_day,
    fire_weather_index
)
SELECT 
    -- 1. CHAVE TEMPORAL (Day ID: YYYYMMDD)
    COALESCE(
        (YEAR(TRY_CAST(src.[date] AS DATE)) * 10000) + 
        (MONTH(TRY_CAST(src.[date] AS DATE)) * 100) + 
        DAY(TRY_CAST(src.[date] AS DATE)), 
    -1) AS day_id,

    -- 2. CHAVE ESPACIAL (Location ID via Incêndio)
    COALESCE(loc.location_id, -1) AS location_id,

    -- 3. MÉTRICAS (Conversão Texto -> Float com tratamento de vírgula)
    TRY_CAST(REPLACE(src.temp_max, ',', '.') AS FLOAT) AS temp_max,
    TRY_CAST(REPLACE(src.temp_min, ',', '.') AS FLOAT) AS temp_min,
    -- Cálculo da Média
    (TRY_CAST(REPLACE(src.temp_max, ',', '.') AS FLOAT) + TRY_CAST(REPLACE(src.temp_min, ',', '.') AS FLOAT)) / 2.0 AS temp_mean,

    TRY_CAST(REPLACE(src.rh_max, ',', '.') AS FLOAT) AS rh_max,
    TRY_CAST(REPLACE(src.rh_min, ',', '.') AS FLOAT) AS rh_min,
    -- Média RH
    (TRY_CAST(REPLACE(src.rh_max, ',', '.') AS FLOAT) + TRY_CAST(REPLACE(src.rh_min, ',', '.') AS FLOAT)) / 2.0 AS rh_mean,

    TRY_CAST(REPLACE(src.precip_sum, ',', '.') AS FLOAT) AS precip_sum,
    TRY_CAST(REPLACE(src.rain_sum, ',', '.') AS FLOAT) AS rain_sum,
    TRY_CAST(REPLACE(src.precip_hours, ',', '.') AS INT) AS precip_hours,

    TRY_CAST(REPLACE(src.wind_max, ',', '.') AS FLOAT) AS wind_max,
    TRY_CAST(REPLACE(src.gust_max, ',', '.') AS FLOAT) AS gust_max,
    TRY_CAST(REPLACE(src.wind_dir, ',', '.') AS FLOAT) AS wind_dir,
    NULL AS wind_speed_mean,

    TRY_CAST(REPLACE(src.radiation, ',', '.') AS FLOAT) AS radiation,
    TRY_CAST(REPLACE(src.sunshine, ',', '.') AS FLOAT) AS sunshine,
    NULL AS shortwave_radiation,

    TRY_CAST(REPLACE(src.et0, ',', '.') AS FLOAT) AS et0,

    NULL AS pressure_msl,
    NULL AS cloud_cover,

    -- 4. FLAGS (Calculadas)
    -- Dia Seco (se precip <= 0 ou NULL)
    CASE 
        WHEN TRY_CAST(REPLACE(src.precip_sum, ',', '.') AS FLOAT) <= 0 OR src.precip_sum IS NULL THEN 1 
        ELSE 0 
    END AS is_dry_day,

    -- Dia Vento Forte (> 30 km/h)
    CASE 
        WHEN TRY_CAST(REPLACE(src.wind_max, ',', '.') AS FLOAT) > 30 THEN 1 
        ELSE 0 
    END AS is_high_wind_day,

    NULL AS fire_weather_index

FROM UniqueMeteo src -- <--- Usa a CTE Local

-- JOIN com Incêndios Locais (para saber onde foi o incidente)
LEFT JOIN [dbo].[dsa_icnf_fire] f ON src.incident_id = f.id

-- JOIN com Dimensão Remota (DW) para obter o ID da localização
LEFT JOIN [DW.TAAD].[dbo].[dim_location] loc ON 
    loc.district     = TRIM(UPPER(COALESCE(f.DISTRITO, N'Desconhecido'))) AND
    loc.municipality = TRIM(UPPER(COALESCE(f.CONCELHO, N'Desconhecido'))) AND
    loc.parish       = TRIM(UPPER(COALESCE(f.FREGUESIA, N'Desconhecido')))

WHERE 
    src.rn = 1 -- Garante unicidade na origem
    AND NOT EXISTS (
        -- Garante que não duplica no destino
        SELECT 1 FROM [DW.TAAD].[dbo].[fact_daily_meteorology] tgt 
        WHERE tgt.day_id = (YEAR(TRY_CAST(src.[date] AS DATE)) * 10000) + (MONTH(TRY_CAST(src.[date] AS DATE)) * 100) + DAY(TRY_CAST(src.[date] AS DATE))
          AND tgt.location_id = loc.location_id
    );