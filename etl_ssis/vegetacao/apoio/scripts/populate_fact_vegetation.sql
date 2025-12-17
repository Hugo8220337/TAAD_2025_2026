/*
    Script: populate_fact_vegetation.sql (Versão Lookup via fact_fire)
    Objetivo: Carregar factos de vegetação cruzando com fact_fire para obter contexto geográfico.
    Origem: [DSA.TAAD].[dbo].[dsa_vegetation] + [DW.TAAD].[dbo].[fact_fire]
    Destino: [DW.TAAD].[dbo].[fact_vegetation]
*/

INSERT INTO [DW.TAAD].[dbo].[fact_vegetation] (
    -- Chaves Estrangeiras (FKs)
    day_id,
    location_id,
    landcover_id, -- Ficará como -1 (não disponível na fonte atual)
    species_id,   -- Ficará como -1 (não disponível na fonte atual)

    -- Atributos de Contexto
    time_window,
    external_fire_id,

    -- Métricas (Measures)
    area_m2,       -- Convertido de ha para m2
    ndvi_mean,
    ndvi_std,
    ndvi_count,
    pct_area_ndvi_gt_thr,
    
    -- Colunas opcionais (definidas como NULL se não existirem na staging nova)
    ndvi_median,
    veg_density_mean,
    fuel_index,
    
    -- Auditoria
    processing_date
)
SELECT 
    -------------------------------------------------------
    -- 1. CHAVE TEMPORAL (Baseada no t0 da Staging)
    -------------------------------------------------------
    -- Converte '2024-05-24' para 20240524
    COALESCE(
        (YEAR(TRY_CAST(src.t0 AS DATE)) * 10000) + 
        (MONTH(TRY_CAST(src.t0 AS DATE)) * 100) + 
        DAY(TRY_CAST(src.t0 AS DATE)), 
        -1
    ) AS day_id,

    -------------------------------------------------------
    -- 2. LOOKUP DE LOCALIZAÇÃO (Via fact_fire)
    -------------------------------------------------------
    -- Vai buscar o location_id associado ao incêndio na tabela de factos de incêndio [cite: 6]
    COALESCE(ff.location_id, -1) AS location_id,

    -------------------------------------------------------
    -- 3. DIMENSÕES EM FALTA (Landcover/Species)
    -------------------------------------------------------
    -- Como a staging só tem métricas e o fact_fire não tem detalhe de solo/espécie,
    -- definimos como -1 (Desconhecido).
    -1 AS landcover_id,
    -1 AS species_id,

    -------------------------------------------------------
    -- 4. ATRIBUTOS DE CONTEXTO
    -------------------------------------------------------
    src.time_window,
    src.fire_id AS external_fire_id, -- Mantemos o ID original para referência visual

    -------------------------------------------------------
    -- 5. CONVERSÃO DE MÉTRICAS
    -------------------------------------------------------
    -- Conversão de Hectares (staging) para m2 (DW) 
    -- 1 ha = 10,000 m2
    (TRY_CAST(REPLACE(src.area_ha, ',', '.') AS FLOAT) * 10000.0) AS area_m2,

    TRY_CAST(REPLACE(src.ndvi_mean, ',', '.') AS FLOAT) AS ndvi_mean,
    TRY_CAST(REPLACE(src.ndvi_std, ',', '.') AS FLOAT) AS ndvi_std,
    TRY_CAST(REPLACE(src.ndvi_count, ',', '.') AS INT) AS ndvi_count,
    TRY_CAST(REPLACE(src.pct_area_ndvi_gt_thr, ',', '.') AS FLOAT) AS pct_area_ndvi_gt_thr,
    
    -- Campos que não existem na staging nova vão como NULL
    NULL AS ndvi_median,
    NULL AS veg_density_mean,
    NULL AS fuel_index,

    -- Data de processamento
    SYSUTCDATETIME()

FROM [DSA.TAAD].[dbo].[dsa_vegetation] src

-- JOIN com a Fact Table de Incêndios para recuperar a localização
LEFT JOIN [DW.TAAD].[dbo].[fact_fire] ff [cite: 6]
    ON src.fire_id = ff.fire_id

WHERE 
    -- Garante que temos uma data válida
    TRY_CAST(src.t0 AS DATE) IS NOT NULL
    
    -- Evitar duplicados (Idempotência)
    AND NOT EXISTS (
        SELECT 1 FROM [DW.TAAD].[dbo].[fact_vegetation] tgt
        WHERE tgt.external_fire_id = src.fire_id
          AND tgt.time_window = src.time_window
          AND tgt.day_id = (YEAR(TRY_CAST(src.t0 AS DATE)) * 10000) + (MONTH(TRY_CAST(src.t0 AS DATE)) * 100) + DAY(TRY_CAST(src.t0 AS DATE))
    );