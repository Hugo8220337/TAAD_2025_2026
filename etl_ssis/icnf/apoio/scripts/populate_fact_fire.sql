/*
    Script: populate_fact_fire.sql
    Objetivo: Carregar a tabela de factos transformando chaves de negócio em chaves (IDs) das dimensões.
*/

-- 1. Limpar dados antigos (opcional: depende se queres carga total ou incremental)
-- TRUNCATE TABLE [DW.TAAD].[dbo].[fact_fire]; 

INSERT INTO [DW.TAAD].[dbo].[fact_fire] (
    fire_id,
    
    -- Chaves Temporais
    alert_hour_id,
    extinguish_hour_id,
    first_intervention_hour_id,
    start_day_id,
    end_day_id,
    
    -- Chaves das Dimensões
    location_id,
    fire_type_id,
    cause_id,
    
    -- Métricas (Convertendo texto com vírgula para float com ponto)
    area_total_m2,
    area_pov_m2,
    area_shrub_m2,
    area_agri_m2,
    duration_hours,
    perimeter_m,
    latitude,
    longitude,
    
    -- Outros contadores
    ndays
)
SELECT 
    src.id AS fire_id,

    -------------------------------------------------------
    -- 1. CALCULO DAS HORAS (Extrair hora do texto HH:MM)
    -------------------------------------------------------
    CASE 
        WHEN src.HORAALERTA LIKE '%:%' THEN TRY_CAST(LEFT(src.HORAALERTA, CHARINDEX(':', src.HORAALERTA) - 1) AS INT)
        WHEN ISNUMERIC(src.HORAALERTA) = 1 AND LEN(src.HORAALERTA) <= 2 THEN TRY_CAST(src.HORAALERTA AS INT)
        ELSE -1 
    END AS alert_hour_id,

    CASE 
        WHEN src.HORAEXTINCAO LIKE '%:%' THEN TRY_CAST(LEFT(src.HORAEXTINCAO, CHARINDEX(':', src.HORAEXTINCAO) - 1) AS INT)
        ELSE -1 
    END AS extinguish_hour_id,

    CASE 
        WHEN src.HORA1INTERVENCAO LIKE '%:%' THEN TRY_CAST(LEFT(src.HORA1INTERVENCAO, CHARINDEX(':', src.HORA1INTERVENCAO) - 1) AS INT)
        ELSE -1 
    END AS first_intervention_hour_id,

    -------------------------------------------------------
    -- 2. CALCULO DOS DIAS (Formato AAAAMMDD)
    -------------------------------------------------------
    COALESCE(
        (YEAR(TRY_CAST(src.DATAALERTA AS DATE)) * 10000) + 
        (MONTH(TRY_CAST(src.DATAALERTA AS DATE)) * 100) + 
        DAY(TRY_CAST(src.DATAALERTA AS DATE)), 
    -1) AS start_day_id,

    COALESCE(
        (YEAR(TRY_CAST(src.DATAEXTINCAO AS DATE)) * 10000) + 
        (MONTH(TRY_CAST(src.DATAEXTINCAO AS DATE)) * 100) + 
        DAY(TRY_CAST(src.DATAEXTINCAO AS DATE)), 
    -1) AS end_day_id,

    -------------------------------------------------------
    -- 3. LOOKUPS PARA AS DIMENSÕES (Joins)
    -------------------------------------------------------
    
    -- Localização: Se não encontrar, usa -1 (Desconhecido)
    COALESCE(loc.location_id, -1) AS location_id,
    
    -- Tipo de Fogo
    COALESCE(ft.fire_type_id, -1) AS fire_type_id,
    
    -- Causa
    COALESCE(cau.cause_id, -1) AS cause_id,

    -------------------------------------------------------
    -- 4. CONVERSÃO DE MÉTRICAS (Texto -> Float)
    -- Nota: Substitui vírgula por ponto antes de converter
    -------------------------------------------------------
    TRY_CAST(REPLACE(src.AREATOTAL, ',', '.') AS FLOAT) AS area_total_m2,
    TRY_CAST(REPLACE(src.AREAPOV, ',', '.') AS FLOAT) AS area_pov_m2,
    TRY_CAST(REPLACE(src.AREAMATO, ',', '.') AS FLOAT) AS area_shrub_m2,
    TRY_CAST(REPLACE(src.AREAAGRIC, ',', '.') AS FLOAT) AS area_agri_m2,
    TRY_CAST(REPLACE(src.DURACAO, ',', '.') AS FLOAT) AS duration_hours,
    TRY_CAST(REPLACE(src.PERIMETRO, ',', '.') AS FLOAT) AS perimeter_m,
    
    TRY_CAST(REPLACE(src.LAT, ',', '.') AS FLOAT) AS latitude,
    TRY_CAST(REPLACE(src.LON, ',', '.') AS FLOAT) AS longitude,

    -- Campos inteiros simples (assumindo que já vêm limpos ou NULL)
    0 AS ndays         -- Placeholder (podes calcular datediff)

FROM dbo.dsa_icnf_fire src

-- JOIN LOCALIZAÇÃO
LEFT JOIN [DW.TAAD].[dbo].[dim_location] loc ON 
    loc.district     = TRIM(UPPER(COALESCE(src.DISTRITO, N'Desconhecido'))) AND
    loc.municipality = TRIM(UPPER(COALESCE(src.CONCELHO, N'Desconhecido'))) AND
    loc.parish       = TRIM(UPPER(COALESCE(src.FREGUESIA, N'Desconhecido')))

-- JOIN CAUSA
LEFT JOIN [DW.TAAD].[dbo].[dim_cause] cau ON 
    cau.cause_name     = TRIM(UPPER(COALESCE(src.CAUSA, N'Desconhecido'))) AND
    cau.cause_category = TRIM(UPPER(COALESCE(src.TIPOCAUSA, N'Desconhecido'))) AND
    cau.cause_family   = TRIM(UPPER(COALESCE(src.CAUSAFAMILIA, N'Desconhecido')))

-- JOIN TIPO DE FOGO (Atenção aos bits/flags)
LEFT JOIN [DW.TAAD].[dbo].[dim_fire_type] ft ON 
    ft.type_name = TRIM(UPPER(COALESCE(src.TIPO, N'Desconhecido'))) AND
    ft.is_control_burn = (CASE WHEN TRIM(src.QUEIMADA) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END) AND
    ft.is_false_alarm  = (CASE WHEN TRIM(src.FALSOALARME) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END) AND
    ft.is_agricultural = (CASE WHEN TRIM(src.AGRICOLA) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END)

WHERE 
    -- Evitar duplicar dados se correr o script duas vezes
    NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[fact_fire] f WHERE f.fire_id = src.id);