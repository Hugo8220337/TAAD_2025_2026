/*
    Script: populate_fact_vegetation.sql
    Origem: [DSA.TAAD].[dbo].[dsa_vegetation]
    Destino: [DW.TAAD].[dbo].[fact_vegetation]
*/

INSERT INTO [DW.TAAD].[dbo].[fact_vegetation] (
    -- Chaves Estrangeiras (FKs)
    day_id,
    location_id,
    landcover_id,
    species_id,

    -- Atributos de Contexto
    time_window,
    external_fire_id,

    -- Métricas (Measures)
    area_m2,
    ndvi_mean,
    ndvi_median,
    ndvi_std,
    ndvi_count,
    pct_area_ndvi_gt_thr,
    veg_density_mean,
    fuel_index,
    
    -- Auditoria
    processing_date
)
SELECT 
    -------------------------------------------------------
    -- 1. CHAVE TEMPORAL (Day ID)
    -------------------------------------------------------
    -- Assume-se que o day_id na staging já vem como 'AAAAMMDD' ou data convertível
    COALESCE(
        TRY_CAST(src.day_id AS INT),
        -1
    ) AS day_id,

    -------------------------------------------------------
    -- 2. LOOKUPS PARA AS DIMENSÕES (Joins)
    -- Se o LEFT JOIN falhar (NULL), usa -1 (Desconhecido)
    -------------------------------------------------------
    COALESCE(loc.location_id, -1) AS location_id,
    COALESCE(lc.landcover_id, -1) AS landcover_id,
    COALESCE(sp.species_id, -1) AS species_id,

    -------------------------------------------------------
    -- 3. ATRIBUTOS DIRETOS
    -------------------------------------------------------
    src.time_window,
    src.external_fire_id,

    -------------------------------------------------------
    -- 4. CONVERSÃO DE MÉTRICAS (Texto -> Float/Int)
    -- Nota: Substitui vírgula por ponto para garantir compatibilidade SQL
    -------------------------------------------------------
    TRY_CAST(REPLACE(src.area_m2, ',', '.') AS FLOAT) AS area_m2,
    TRY_CAST(REPLACE(src.ndvi_mean, ',', '.') AS FLOAT) AS ndvi_mean,
    TRY_CAST(REPLACE(src.ndvi_median, ',', '.') AS FLOAT) AS ndvi_median,
    TRY_CAST(REPLACE(src.ndvi_std, ',', '.') AS FLOAT) AS ndvi_std,
    TRY_CAST(REPLACE(src.ndvi_count, ',', '.') AS INT) AS ndvi_count, -- Count é inteiro
    TRY_CAST(REPLACE(src.pct_area_ndvi_gt_thr, ',', '.') AS FLOAT) AS pct_area_ndvi_gt_thr,
    TRY_CAST(REPLACE(src.veg_density_mean, ',', '.') AS FLOAT) AS veg_density_mean,
    TRY_CAST(REPLACE(src.fuel_index, ',', '.') AS FLOAT) AS fuel_index,

    -- Data de processamento atual
    SYSUTCDATETIME()

[cite_start]FROM [DSA.TAAD].[dbo].[dsa_vegetation] src [cite: 1]

-- JOIN LOCALIZAÇÃO
-- Tenta corresponder Distrito, Concelho e Freguesia
[cite_start]LEFT JOIN [DW.TAAD].[dbo].[dim_location] loc [cite: 4] ON 
    loc.district     = TRIM(UPPER(COALESCE(src.district, N'Desconhecido'))) AND
    loc.municipality = TRIM(UPPER(COALESCE(src.municipality, N'Desconhecido'))) AND
    loc.parish       = TRIM(UPPER(COALESCE(src.parish, N'Desconhecido')))

-- JOIN OCUPAÇÃO DO SOLO (Landcover)
-- Tenta corresponder Código Corine, Descrição e Categoria de Combustível
[cite_start]LEFT JOIN [DW.TAAD].[dbo].[dim_landcover] lc [cite: 5] ON 
    lc.corine_code        = TRY_CAST(src.corine_code AS INT) AND
    lc.corine_description = TRIM(COALESCE(src.corine_description, N'Desconhecido')) AND
    lc.fuel_category      = TRIM(COALESCE(src.fuel_category, N'Desconhecido'))

-- JOIN ESPÉCIES
-- Tenta corresponder o nome da espécie
[cite_start]LEFT JOIN [DW.TAAD].[dbo].[dim_species] sp [cite: 5] ON 
    sp.species_name = TRIM(UPPER(COALESCE(src.species_name, N'Desconhecido')))

WHERE 
    -- Validação básica para ignorar linhas totalmente vazias ou cabeçalhos errados
    TRY_CAST(src.day_id AS INT) IS NOT NULL
    
    -- Evitar duplicados: verifica se já existe um registo com a mesma combinação de dimensões e janela temporal
    AND NOT EXISTS (
        SELECT 1 FROM [DW.TAAD].[dbo].[fact_vegetation] tgt
        WHERE tgt.day_id = COALESCE(TRY_CAST(src.day_id AS INT), -1)
          AND tgt.location_id = COALESCE(loc.location_id, -1)
          AND tgt.landcover_id = COALESCE(lc.landcover_id, -1)
          AND tgt.species_id = COALESCE(sp.species_id, -1)
          AND tgt.time_window = src.time_window
          -- Se necessário, adicionar filtro por external_fire_id para unicidade extra
          AND (tgt.external_fire_id = src.external_fire_id OR (tgt.external_fire_id IS NULL AND src.external_fire_id IS NULL))
    );