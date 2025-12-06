/*
    Script: populate_fact_meteorology.sql
    Objetivo: Carregar a tabela de factos fact_daily_meteorology.
    Lógica: 
      1. Ler dsa_meteorology (Staging).
      2. Obter location_id via dsa_icnf_fire (Incident ID -> Location).
      3. Obter day_id via conversão da data.
*/

-- Opcional: Limpar tabela antes de carregar (se for recarga total)
-- TRUNCATE TABLE dbo.fact_daily_meteorology;

INSERT INTO dbo.fact_daily_meteorology (
    -- Chaves
    day_id,
    location_id,

    -- Temperatura
    temp_max,
    temp_min,
    temp_mean, -- Calculado

    -- Humidade
    rh_max,
    rh_min,
    rh_mean, -- Calculado

    -- Precipitação
    precip_sum,
    rain_sum,
    precip_hours,

    -- Vento
    wind_max,
    gust_max,
    wind_dir,
    wind_speed_mean, -- NULL (não existe na fonte)

    -- Radiação
    radiation,
    sunshine,
    shortwave_radiation, -- NULL (não existe na fonte)

    -- Evapotranspiração
    et0,

    -- Outros (Nuvens, Pressão) - NULL
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
        (YEAR(TRY_CAST(m.[date] AS DATE)) * 10000) + 
        (MONTH(TRY_CAST(m.[date] AS DATE)) * 100) + 
        DAY(TRY_CAST(m.[date] AS DATE)), 
    -1) AS day_id,

    -- 2. CHAVE ESPACIAL (Location ID via Incêndio)
    COALESCE(loc.location_id, -1) AS location_id,

    -- 3. MÉTRICAS (Conversão Texto -> Float com tratamento de vírgula)
    TRY_CAST(REPLACE(m.temp_max, ',', '.') AS FLOAT) AS temp_max,
    TRY_CAST(REPLACE(m.temp_min, ',', '.') AS FLOAT) AS temp_min,
    -- Cálculo Simples da Média: (Max + Min) / 2
    (TRY_CAST(REPLACE(m.temp_max, ',', '.') AS FLOAT) + TRY_CAST(REPLACE(m.temp_min, ',', '.') AS FLOAT)) / 2.0 AS temp_mean,

    TRY_CAST(REPLACE(m.rh_max, ',', '.') AS FLOAT) AS rh_max,
    TRY_CAST(REPLACE(m.rh_min, ',', '.') AS FLOAT) AS rh_min,
    (TRY_CAST(REPLACE(m.rh_max, ',', '.') AS FLOAT) + TRY_CAST(REPLACE(m.rh_min, ',', '.') AS FLOAT)) / 2.0 AS rh_mean,

    TRY_CAST(REPLACE(m.precip_sum, ',', '.') AS FLOAT) AS precip_sum,
    TRY_CAST(REPLACE(m.rain_sum, ',', '.') AS FLOAT) AS rain_sum,
    TRY_CAST(REPLACE(m.precip_hours, ',', '.') AS INT) AS precip_hours,

    TRY_CAST(REPLACE(m.wind_max, ',', '.') AS FLOAT) AS wind_max,
    TRY_CAST(REPLACE(m.gust_max, ',', '.') AS FLOAT) AS gust_max,
    TRY_CAST(REPLACE(m.wind_dir, ',', '.') AS FLOAT) AS wind_dir,
    NULL AS wind_speed_mean,

    TRY_CAST(REPLACE(m.radiation, ',', '.') AS FLOAT) AS radiation,
    TRY_CAST(REPLACE(m.sunshine, ',', '.') AS FLOAT) AS sunshine,
    NULL AS shortwave_radiation,

    TRY_CAST(REPLACE(m.et0, ',', '.') AS FLOAT) AS et0,

    NULL AS pressure_msl,
    NULL AS cloud_cover,

    -- 4. FLAGS (Cálculos de Negócio)
    -- Dia Seco: Se precipitação acumulada for 0 ou NULL
    CASE 
        WHEN TRY_CAST(REPLACE(m.precip_sum, ',', '.') AS FLOAT) <= 0 OR m.precip_sum IS NULL THEN 1 
        ELSE 0 
    END AS is_dry_day,

    -- Dia de Vento Forte: Exemplo > 30 km/h (ajustar conforme regra de negócio)
    CASE 
        WHEN TRY_CAST(REPLACE(m.wind_max, ',', '.') AS FLOAT) > 30 THEN 1 
        ELSE 0 
    END AS is_high_wind_day,

    NULL AS fire_weather_index

FROM dbo.dsa_meteorology m

-- JOIN para obter o Incêndio original (para saber a localização)
LEFT JOIN dbo.dsa_icnf_fire f ON m.incident_id = f.id

-- JOIN para obter o ID da Localização
LEFT JOIN dbo.dim_location loc ON 
    loc.district     = TRIM(UPPER(COALESCE(f.DISTRITO, N'Desconhecido'))) AND
    loc.municipality = TRIM(UPPER(COALESCE(f.CONCELHO, N'Desconhecido'))) AND
    loc.parish       = TRIM(UPPER(COALESCE(f.FREGUESIA, N'Desconhecido')))

-- Evitar duplicados exatos (caso corra o script várias vezes)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.fact_daily_meteorology tgt 
    WHERE tgt.day_id = (YEAR(TRY_CAST(m.[date] AS DATE)) * 10000) + (MONTH(TRY_CAST(m.[date] AS DATE)) * 100) + DAY(TRY_CAST(m.[date] AS DATE))
      AND tgt.location_id = loc.location_id
);