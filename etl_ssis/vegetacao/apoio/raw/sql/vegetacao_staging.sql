IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.dsa_vegetation') AND type = N'U'
)
BEGIN
CREATE TABLE dbo.dsa_vegetation (
    -- Identificador único do registo na origem (se existir), caso contrário gerar na ingestão
    id INT IDENTITY(1,1) NOT NULL,

    -- Campos Temporais (Baseado em dim_day)
    day_id NVARCHAR(MAX) NULL,          -- ex: 20250211
    processing_date NVARCHAR(MAX) NULL, -- Data de processamento do registo

    -- Campos Geográficos (Baseado em dim_location)
    district NVARCHAR(MAX) NULL,      -- Distrito
    municipality NVARCHAR(MAX) NULL,  -- Concelho
    parish NVARCHAR(MAX) NULL,        -- Freguesia
    nuts3 NVARCHAR(MAX) NULL,         -- Código NUTS3

    -- Campos de Ocupação de Solo (Baseado em dim_landcover)
    corine_code NVARCHAR(MAX) NULL,         -- Código Corine Land Cover
    corine_description NVARCHAR(MAX) NULL,  -- Descrição
    fuel_category NVARCHAR(MAX) NULL,       -- Categoria de combustível (Forest/Shrub)
    
    -- Campos de Espécies (Baseado em dim_species)
    species_name NVARCHAR(MAX) NULL,        -- Espécie dominante

    -- Métricas / Factos (Baseado em fact_vegetation)
    time_window NVARCHAR(MAX) NULL,         -- ex: pre_30, annual_2023
    area_m2 NVARCHAR(MAX) NULL,             -- Área do polígono
    ndvi_mean NVARCHAR(MAX) NULL,           -- Média NDVI
    ndvi_median NVARCHAR(MAX) NULL,         -- Mediana NDVI
    ndvi_std NVARCHAR(MAX) NULL,            -- Desvio padrão
    ndvi_count NVARCHAR(MAX) NULL,          -- Contagem de pixels válidos
    pct_area_ndvi_gt_thr NVARCHAR(MAX) NULL, -- % área acima do limiar
    veg_density_mean NVARCHAR(MAX) NULL,    -- Densidade vegetação
    fuel_index NVARCHAR(MAX) NULL,          -- Índice de combustível

    -- Ligações Externas
    external_fire_id NVARCHAR(MAX) NULL,    -- ID para join visual com dataset de fogos

    -- Metadados de Ingestão
    load_file NVARCHAR(MAX) NULL,
    load_datetime DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_dsa_vegetation PRIMARY KEY CLUSTERED (id)
);
END