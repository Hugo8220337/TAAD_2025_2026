/*
    Script: populate_fact_vegetation_fixed.sql
    Objetivo: Popular a fact_vegetation copiando o location_id da fact_fire.
    Correção: Garante o JOIN robusto entre o ID do fogo da vegetação e o ID da tabela de factos.
*/

INSERT INTO [DW.TAAD].[dbo].[fact_vegetation] (
    day_id,
    location_id,      -- Vamos buscar este valor à tabela fact_fire
    time_window,
    external_fire_id, -- Chave de ligação
    area_m2,
    ndvi_mean,
    ndvi_std,
    ndvi_count,
    pct_area_ndvi_gt_thr,
    processing_date
)
SELECT 
    -- 1. DATA: ID YYYYMMDD
    COALESCE(
        (YEAR(TRY_CAST(src.t0 AS DATE)) * 10000) + 
        (MONTH(TRY_CAST(src.t0 AS DATE)) * 100) + 
        DAY(TRY_CAST(src.t0 AS DATE)), 
        -1
    ) AS day_id,

    -- 2. LOCALIZAÇÃO: Copiada da fact_fire através do JOIN
    -- Se o JOIN falhar, fica -1. Se funcionar, traz o ID correto (ex: 342)
    COALESCE(ff.location_id, -1) AS location_id,

    -- 3. Identificadores
    src.time_window,
    src.fire_id AS external_fire_id,

    -- 4. MÉTRICAS (ha -> m2 e tratamento de decimais)
    (TRY_CAST(REPLACE(src.area_ha, ',', '.') AS FLOAT) * 10000.0) AS area_m2,
    TRY_CAST(REPLACE(src.ndvi_mean, ',', '.') AS FLOAT) AS ndvi_mean,
    TRY_CAST(REPLACE(src.ndvi_std, ',', '.') AS FLOAT) AS ndvi_std,
    TRY_CAST(REPLACE(src.ndvi_count, ',', '.') AS INT) AS ndvi_count,
    TRY_CAST(REPLACE(src.pct_area_ndvi_gt_thr, ',', '.') AS FLOAT) AS pct_area_ndvi_gt_thr,

    SYSUTCDATETIME()

FROM [DSA.TAAD].[dbo].[dsa_vegetation] src

-- TRIM e UPPER para garantir que ' BI123 ' iguala a 'BI123'
LEFT JOIN [DW.TAAD].[dbo].[fact_fire] ff 
    ON ff.fire_id LIKE '%' + TRIM(src.fire_id) + '%'

WHERE 
    TRY_CAST(src.t0 AS DATE) IS NOT NULL
    AND NOT EXISTS (
        -- Evita duplicados
        SELECT 1 FROM [DW.TAAD].[dbo].[fact_vegetation] tgt
        WHERE tgt.external_fire_id = src.fire_id
          AND tgt.time_window = src.time_window
    );