/*
    Script: populate_fact_vegetation.sql
    Origem: [DSA.TAAD].[dbo].[dsa_vegetation] (Colunas iguais ao CSV)
    Destino: [DW.TAAD].[dbo].[fact_vegetation]
*/

INSERT INTO [DW.TAAD].[dbo].[fact_vegetation] (
    day_id,
    location_id,
    time_window,
    external_fire_id,
    area_m2,
    ndvi_mean,
    ndvi_std,
    ndvi_count,
    pct_area_ndvi_gt_thr,
    processing_date
)
SELECT 
    -- 1. DATA: Converte 't0' (YYYY-MM-DD) para ID (YYYYMMDD)
    COALESCE(
        (YEAR(TRY_CAST(src.t0 AS DATE)) * 10000) + 
        (MONTH(TRY_CAST(src.t0 AS DATE)) * 100) + 
        DAY(TRY_CAST(src.t0 AS DATE)), 
        -1
    ) AS day_id,

    -- 2. LOCALIZAÇÃO: Busca o location_id do incêndio correspondente
    COALESCE(ff.location_id, -1) AS location_id,

    -- 3. CONTEXTO
    src.time_window,
    src.fire_id,

    -- 4. MÉTRICAS (Conversão de texto para número)
    (TRY_CAST(REPLACE(src.area_ha, ',', '.') AS FLOAT) * 10000.0) AS area_m2, -- ha -> m2
    TRY_CAST(REPLACE(src.ndvi_mean, ',', '.') AS FLOAT),
    TRY_CAST(REPLACE(src.ndvi_std, ',', '.') AS FLOAT),
    TRY_CAST(REPLACE(src.ndvi_count, ',', '.') AS INT),
    TRY_CAST(REPLACE(src.pct_area_ndvi_gt_thr, ',', '.') AS FLOAT),

    -- Data de processamento
    SYSUTCDATETIME()

FROM [DSA.TAAD].[dbo].[dsa_vegetation] src
LEFT JOIN [DW.TAAD].[dbo].[fact_fire] ff 
    ON src.fire_id = ff.fire_id -- Cruza pelo ID do fogo para saber onde foi

WHERE 
    TRY_CAST(src.t0 AS DATE) IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM [DW.TAAD].[dbo].[fact_vegetation] tgt
        WHERE tgt.external_fire_id = src.fire_id
          AND tgt.time_window = src.time_window
    );