/*
    Script: populate_fact_meteorology_simple.sql
    Objetivo: Popular a tabela de factos de meteorologia copiando o location_id diretamente da staging.
*/

-- CTE para garantir unicidade (remove duplicados se existirem na origem)
WITH UniqueMeteo AS (
    SELECT 
        *,
        ROW_NUMBER() OVER(PARTITION BY incident_id, [date] ORDER BY load_datetime DESC) as rn
    FROM [dbo].[dsa_meteorology]
)
INSERT INTO [DW.TAAD].[dbo].[fact_daily_meteorology] (
    day_id,
    location_id, -- Copiado diretamente
    temp_max,
    temp_min,
    temp_mean,
    rh_max,
    rh_min,
    rh_mean,
    precip_sum,
    rain_sum,
    precip_hours,
    wind_max,
    gust_max,
    wind_dir,
    wind_speed_mean,
    radiation,
    sunshine,
    shortwave_radiation,
    et0,
    pressure_msl,
    cloud_cover,
    is_dry_day,
    is_high_wind_day,
    fire_weather_index,
    processing_date
)
SELECT 
    -- 1. Day ID (Calculado a partir da data YYYY-MM-DD)
    COALESCE(
        (YEAR(TRY_CAST(src.[date] AS DATE)) * 10000) + 
        (MONTH(TRY_CAST(src.[date] AS DATE)) * 100) + 
        DAY(TRY_CAST(src.[date] AS DATE)), 
    -1) AS day_id,

    -- 2. Location ID (Cópia direta da Staging)
    -- Assume que a coluna 'location_id' existe na tabela dsa_meteorology
    COALESCE(TRY_CAST(src.location_id AS INT), -1) AS location_id,

    -- 3. Métricas (Tratamento de vírgulas e conversão para FLOAT)
    TRY_CAST(REPLACE(src.temp_max, ',', '.') AS FLOAT) AS temp_max,
    TRY_CAST(REPLACE(src.temp_min, ',', '.') AS FLOAT) AS temp_min,
    (TRY_CAST(REPLACE(src.temp_max, ',', '.') AS FLOAT) + TRY_CAST(REPLACE(src.temp_min, ',', '.') AS FLOAT)) / 2.0 AS temp_mean,

    TRY_CAST(REPLACE(src.rh_max, ',', '.') AS FLOAT) AS rh_max,
    TRY_CAST(REPLACE(src.rh_min, ',', '.') AS FLOAT) AS rh_min,
    (TRY_CAST(REPLACE(src.rh_max, ',', '.') AS FLOAT) + TRY_CAST(REPLACE(src.rh_min, ',', '.') AS FLOAT)) / 2.0 AS rh_mean,

    TRY_CAST(REPLACE(src.precip_sum, ',', '.') AS FLOAT) AS precip_sum,
    TRY_CAST(REPLACE(src.rain_sum, ',', '.') AS FLOAT) AS rain_sum,
    TRY_CAST(REPLACE(src.precip_hours, ',', '.') AS INT) AS precip_hours,

    TRY_CAST(REPLACE(src.wind_max, ',', '.') AS FLOAT) AS wind_max,
    TRY_CAST(REPLACE(src.gust_max, ',', '.') AS FLOAT) AS gust_max,
    TRY_CAST(REPLACE(src.wind_dir, ',', '.') AS FLOAT) AS wind_dir,
    NULL AS wind_speed_mean, -- Não presente na staging original

    TRY_CAST(REPLACE(src.radiation, ',', '.') AS FLOAT) AS radiation,
    TRY_CAST(REPLACE(src.sunshine, ',', '.') AS FLOAT) AS sunshine,
    NULL AS shortwave_radiation,

    TRY_CAST(REPLACE(src.et0, ',', '.') AS FLOAT) AS et0,
    NULL AS pressure_msl,
    NULL AS cloud_cover,

    -- 4. Flags (Calculadas)
    CASE 
        WHEN TRY_CAST(REPLACE(src.precip_sum, ',', '.') AS FLOAT) <= 0 OR src.precip_sum IS NULL THEN 1 
        ELSE 0 
    END AS is_dry_day,
    CASE 
        WHEN TRY_CAST(REPLACE(src.wind_max, ',', '.') AS FLOAT) > 30 THEN 1 
        ELSE 0 
    END AS is_high_wind_day,
    NULL AS fire_weather_index,
    
    SYSUTCDATETIME()

FROM UniqueMeteo src
WHERE 
    src.rn = 1 -- Apenas a versão mais recente de cada registo
    AND NOT EXISTS (
        -- Evita duplicados verificando se já existe na tabela de destino
        SELECT 1 FROM [DW.TAAD].[dbo].[fact_daily_meteorology] tgt 
        WHERE tgt.day_id = (YEAR(TRY_CAST(src.[date] AS DATE)) * 10000) + (MONTH(TRY_CAST(src.[date] AS DATE)) * 100) + DAY(TRY_CAST(src.[date] AS DATE))
          AND tgt.location_id = TRY_CAST(src.location_id AS INT)
    );