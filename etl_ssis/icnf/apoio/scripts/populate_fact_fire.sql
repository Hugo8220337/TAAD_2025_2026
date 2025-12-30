/*
    Script: populate_fact_fire.sql
    Objetivo: Popular a tabela de factos mantendo o ID original da Staging.
*/

INSERT INTO [DW.TAAD].[dbo].[fact_fire] (
    fire_id,                    -- Recebe o ID original da Staging (ex: "202210141517013")
    alert_hour_id,
    extinguish_hour_id,
    first_intervention_hour_id,
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
    UniqueSource.staging_id,    -- Mapeado diretamente do src.id
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
    SELECT 
        src.id AS staging_id, -- O ID da staging é preservado aqui

        -- 1. Horas (Extração segura da hora HH)
        COALESCE(CASE 
            WHEN src.HORAALERTA LIKE '%:%' THEN TRY_CAST(LEFT(src.HORAALERTA, CHARINDEX(':', src.HORAALERTA) - 1) AS INT)
            WHEN ISNUMERIC(src.HORAALERTA) = 1 AND LEN(src.HORAALERTA) <= 2 THEN TRY_CAST(src.HORAALERTA AS INT)
        END, -1) AS alert_hour_id,

        COALESCE(CASE 
            WHEN src.HORAEXTINCAO LIKE '%:%' THEN TRY_CAST(LEFT(src.HORAEXTINCAO, CHARINDEX(':', src.HORAEXTINCAO) - 1) AS INT)
            WHEN ISNUMERIC(src.HORAEXTINCAO) = 1 AND LEN(src.HORAEXTINCAO) <= 2 THEN TRY_CAST(src.HORAEXTINCAO AS INT)
        END, -1) AS extinguish_hour_id,

        COALESCE(CASE 
            WHEN src.HORA1INTERVENCAO LIKE '%:%' THEN TRY_CAST(LEFT(src.HORA1INTERVENCAO, CHARINDEX(':', src.HORA1INTERVENCAO) - 1) AS INT)
            WHEN ISNUMERIC(src.HORA1INTERVENCAO) = 1 AND LEN(src.HORA1INTERVENCAO) <= 2 THEN TRY_CAST(src.HORA1INTERVENCAO AS INT)
        END, -1) AS first_intervention_hour_id,

        -- 2. Datas (Prioridade: DHINICIO -> DATAALERTA -> Colunas Ano/Mes/Dia)
        COALESCE(
            (YEAR(TRY_CAST(src.DHINICIO AS DATE)) * 10000) + (MONTH(TRY_CAST(src.DHINICIO AS DATE)) * 100) + DAY(TRY_CAST(src.DHINICIO AS DATE)),
            (YEAR(TRY_CAST(src.DATAALERTA AS DATE)) * 10000) + (MONTH(TRY_CAST(src.DATAALERTA AS DATE)) * 100) + DAY(TRY_CAST(src.DATAALERTA AS DATE)),
            (TRY_CAST(src.ANO AS INT) * 10000) + (TRY_CAST(src.MES AS INT) * 100) + TRY_CAST(src.DIA AS INT),
            -1
        ) AS start_day_id,

        COALESCE(
            (YEAR(TRY_CAST(src.DATAEXTINCAO AS DATE)) * 10000) + (MONTH(TRY_CAST(src.DATAEXTINCAO AS DATE)) * 100) + DAY(TRY_CAST(src.DATAEXTINCAO AS DATE)),
            (YEAR(TRY_CAST(src.DHFIM AS DATE)) * 10000) + (MONTH(TRY_CAST(src.DHFIM AS DATE)) * 100) + DAY(TRY_CAST(src.DHFIM AS DATE)),
            -1
        ) AS end_day_id,

        -- 3. IDs das Dimensões (Lookups)
        COALESCE(loc.location_id, -1) AS location_id,
        COALESCE(ft.fire_type_id, -1) AS fire_type_id,
        COALESCE(cau.cause_id, -1) AS cause_id,

        -- 4. Métricas (Conversão de texto com vírgula para float)
        TRY_CAST(REPLACE(src.AREATOTAL, ',', '.') AS FLOAT) AS area_total_m2,
        TRY_CAST(REPLACE(src.AREAPOV, ',', '.') AS FLOAT) AS area_pov_m2,
        TRY_CAST(REPLACE(src.AREAMATO, ',', '.') AS FLOAT) AS area_shrub_m2,
        TRY_CAST(REPLACE(src.AREAAGRIC, ',', '.') AS FLOAT) AS area_agri_m2,
        TRY_CAST(REPLACE(src.DURACAO, ',', '.') AS FLOAT) AS duration_hours,
        TRY_CAST(REPLACE(src.PERIMETRO, ',', '.') AS FLOAT) AS perimeter_m,
        TRY_CAST(REPLACE(src.LAT, ',', '.') AS FLOAT) AS latitude,
        TRY_CAST(REPLACE(src.LON, ',', '.') AS FLOAT) AS longitude,
        
        -- 5. Outros
        DATEDIFF(DAY, TRY_CAST(src.DATAALERTA AS DATE), TRY_CAST(src.DATAEXTINCAO AS DATE)) AS ndays,
        SYSUTCDATETIME() AS processing_date,

        -- 6. Gestão de Duplicados (Se houver IDs repetidos na staging, pega o mais recente)
        ROW_NUMBER() OVER(PARTITION BY src.id ORDER BY src.load_datetime DESC) as rn

    FROM dbo.dsa_icnf_fire src

    -- Lookup Localização
    LEFT JOIN [DW.TAAD].[dbo].[dim_location] loc ON 
        loc.district     = TRIM(UPPER(COALESCE(src.DISTRITO, N'Desconhecido'))) AND
        loc.municipality = TRIM(UPPER(COALESCE(src.CONCELHO, N'Desconhecido'))) AND
        loc.parish       = TRIM(UPPER(COALESCE(src.FREGUESIA, N'Desconhecido')))

    -- Lookup Causas
    LEFT JOIN [DW.TAAD].[dbo].[dim_cause] cau ON 
        cau.cause_name     = TRIM(UPPER(COALESCE(src.CAUSA, N'Desconhecido'))) AND
        cau.cause_category = TRIM(UPPER(COALESCE(src.TIPOCAUSA, N'Desconhecido'))) AND
        cau.cause_family   = TRIM(UPPER(COALESCE(src.CAUSAFAMILIA, N'Desconhecido')))

    -- Lookup Tipo de Fogo (IMPORTANTE: Inclui as flags booleanas)
    LEFT JOIN [DW.TAAD].[dbo].[dim_fire_type] ft ON 
        ft.type_name = TRIM(UPPER(COALESCE(src.TIPO, N'Desconhecido')))
        AND ft.is_control_burn = CASE WHEN TRIM(src.QUEIMADA) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END
        AND ft.is_false_alarm  = CASE WHEN TRIM(src.FALSOALARME) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END
        AND ft.is_agricultural = CASE WHEN TRIM(src.AGRICOLA) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END

) UniqueSource
WHERE 
    UniqueSource.rn = 1 -- Apenas a primeira ocorrência
    AND NOT EXISTS (    -- Garante que não insere se o ID já existir na tabela de factos
        SELECT 1 FROM [DW.TAAD].[dbo].[fact_fire] tgt 
        WHERE tgt.fire_id = UniqueSource.staging_id
    );