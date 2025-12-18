/*
    Script: populate_fact_fire.sql (Versão Robusta & Idempotente)
    Objetivo: Carregar a tabela de factos de incêndios sem erros de duplicados.
    
    Correções:
    - Deduplicação na origem (ROW_NUMBER)
    - Verificação de existência no destino (WHERE NOT EXISTS)
*/

INSERT INTO [DW.TAAD].[dbo].[fact_fire] (
    fire_id,
    alert_hour_id,
    extinguish_hour_id,
    first_intervention_hour_id,
    
    -- Chaves Temporais
    start_day_id,
    end_day_id,
    
    location_id,
    fire_type_id,
    cause_id,
    area_total_m2,
    area_pov_m2,
    area_shrub_m2,
    area_agri_m2,
    duration_hours,
    perimeter_m,
    latitude,
    longitude,
    ndays,
    processing_date
)
SELECT 
    UniqueSource.fire_id,
    UniqueSource.alert_hour_id,
    UniqueSource.extinguish_hour_id,
    UniqueSource.first_intervention_hour_id,
    UniqueSource.start_day_id,
    UniqueSource.end_day_id,
    UniqueSource.location_id,
    UniqueSource.fire_type_id,
    UniqueSource.cause_id,
    UniqueSource.area_total_m2,
    UniqueSource.area_pov_m2,
    UniqueSource.area_shrub_m2,
    UniqueSource.area_agri_m2,
    UniqueSource.duration_hours,
    UniqueSource.perimeter_m,
    UniqueSource.latitude,
    UniqueSource.longitude,
    UniqueSource.ndays,
    UniqueSource.processing_date
FROM (
    -- Subquery para preparar e deduplicar os dados
    SELECT 
        src.id AS fire_id,

        -- Horas
        COALESCE(CASE 
            WHEN src.HORAALERTA LIKE '%:%' THEN TRY_CAST(LEFT(src.HORAALERTA, CHARINDEX(':', src.HORAALERTA) - 1) AS INT)
            WHEN ISNUMERIC(src.HORAALERTA) = 1 AND LEN(src.HORAALERTA) <= 2 THEN TRY_CAST(src.HORAALERTA AS INT)
        END, -1) AS alert_hour_id,

        COALESCE(CASE 
            WHEN src.HORAEXTINCAO LIKE '%:%' THEN TRY_CAST(LEFT(src.HORAEXTINCAO, CHARINDEX(':', src.HORAEXTINCAO) - 1) AS INT)
        END, -1) AS extinguish_hour_id,

        COALESCE(CASE 
            WHEN src.HORA1INTERVENCAO LIKE '%:%' THEN TRY_CAST(LEFT(src.HORA1INTERVENCAO, CHARINDEX(':', src.HORA1INTERVENCAO) - 1) AS INT)
        END, -1) AS first_intervention_hour_id,

        -- START DAY ID (Fallback Logic)
        COALESCE(
            (YEAR(TRY_CAST(src.DHINICIO AS DATE)) * 10000) + (MONTH(TRY_CAST(src.DHINICIO AS DATE)) * 100) + DAY(TRY_CAST(src.DHINICIO AS DATE)),
            (YEAR(TRY_CAST(src.DATAALERTA AS DATE)) * 10000) + (MONTH(TRY_CAST(src.DATAALERTA AS DATE)) * 100) + DAY(TRY_CAST(src.DATAALERTA AS DATE)),
            (TRY_CAST(src.ANO AS INT) * 10000) + (TRY_CAST(src.MES AS INT) * 100) + TRY_CAST(src.DIA AS INT),
            -1
        ) AS start_day_id,

        -- END DAY ID
        COALESCE(
            (YEAR(TRY_CAST(src.DATAEXTINCAO AS DATE)) * 10000) + (MONTH(TRY_CAST(src.DATAEXTINCAO AS DATE)) * 100) + DAY(TRY_CAST(src.DATAEXTINCAO AS DATE)),
            (YEAR(TRY_CAST(src.DHFIM AS DATE)) * 10000) + (MONTH(TRY_CAST(src.DHFIM AS DATE)) * 100) + DAY(TRY_CAST(src.DHFIM AS DATE)),
            -1
        ) AS end_day_id,

        -- Dimensões (Lookups)
        COALESCE(loc.location_id, -1) AS location_id,
        COALESCE(ft.fire_type_id, -1) AS fire_type_id,
        COALESCE(cau.cause_id, -1) AS cause_id,

        -- Métricas
        TRY_CAST(REPLACE(src.AREATOTAL, ',', '.') AS FLOAT) AS area_total_m2,
        TRY_CAST(REPLACE(src.AREAPOV, ',', '.') AS FLOAT) AS area_pov_m2,
        TRY_CAST(REPLACE(src.AREAMATO, ',', '.') AS FLOAT) AS area_shrub_m2,
        TRY_CAST(REPLACE(src.AREAAGRIC, ',', '.') AS FLOAT) AS area_agri_m2,
        TRY_CAST(REPLACE(src.DURACAO, ',', '.') AS FLOAT) AS duration_hours,
        TRY_CAST(REPLACE(src.PERIMETRO, ',', '.') AS FLOAT) AS perimeter_m,
        TRY_CAST(REPLACE(src.LAT, ',', '.') AS FLOAT) AS latitude,
        TRY_CAST(REPLACE(src.LON, ',', '.') AS FLOAT) AS longitude,
        
        0 AS ndays,
        SYSUTCDATETIME() AS processing_date,

        -- Janela para detetar duplicados na origem (se o ID aparecer 2x, numeramos 1, 2...)
        ROW_NUMBER() OVER(PARTITION BY src.id ORDER BY src.load_datetime DESC) as rn

    FROM dbo.dsa_icnf_fire src

    LEFT JOIN [DW.TAAD].[dbo].[dim_location] loc ON 
        loc.district     = TRIM(UPPER(COALESCE(src.DISTRITO, N'Desconhecido'))) AND
        loc.municipality = TRIM(UPPER(COALESCE(src.CONCELHO, N'Desconhecido'))) AND
        loc.parish       = TRIM(UPPER(COALESCE(src.FREGUESIA, N'Desconhecido')))

    LEFT JOIN [DW.TAAD].[dbo].[dim_cause] cau ON 
        cau.cause_name     = TRIM(UPPER(COALESCE(src.CAUSA, N'Desconhecido'))) AND
        cau.cause_category = TRIM(UPPER(COALESCE(src.TIPOCAUSA, N'Desconhecido'))) AND
        cau.cause_family   = TRIM(UPPER(COALESCE(src.CAUSAFAMILIA, N'Desconhecido')))

    LEFT JOIN [DW.TAAD].[dbo].[dim_fire_type] ft ON 
        ft.type_name = TRIM(UPPER(COALESCE(src.TIPO, N'Desconhecido')))
) UniqueSource
WHERE 
    UniqueSource.rn = 1 -- Apenas a primeira ocorrência de cada ID na origem
    AND NOT EXISTS (    -- Apenas se NÃO existir já no destino
        SELECT 1 FROM [DW.TAAD].[dbo].[fact_fire] tgt 
        WHERE tgt.fire_id = UniqueSource.fire_id
    );