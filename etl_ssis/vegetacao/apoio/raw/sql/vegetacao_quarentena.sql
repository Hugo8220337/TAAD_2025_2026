IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.dsa_vegetation_quarantine') AND type = N'U'
)
BEGIN
CREATE TABLE dbo.dsa_vegetation_quarantine (
    id INT IDENTITY(1,1) NOT NULL,
    
    -- Campos Temporais
    day_id NVARCHAR(MAX) NULL,
    processing_date NVARCHAR(MAX) NULL,

    -- Campos Geográficos
    district NVARCHAR(MAX) NULL,
    municipality NVARCHAR(MAX) NULL,
    parish NVARCHAR(MAX) NULL,
    nuts3 NVARCHAR(MAX) NULL,

    -- Campos de Ocupação de Solo
    corine_code NVARCHAR(MAX) NULL,
    corine_description NVARCHAR(MAX) NULL,
    fuel_category NVARCHAR(MAX) NULL,
    
    -- Campos de Espécies
    species_name NVARCHAR(MAX) NULL,

    -- Métricas / Factos
    time_window NVARCHAR(MAX) NULL,
    area_m2 NVARCHAR(MAX) NULL,
    ndvi_mean NVARCHAR(MAX) NULL,
    ndvi_median NVARCHAR(MAX) NULL,
    ndvi_std NVARCHAR(MAX) NULL,
    ndvi_count NVARCHAR(MAX) NULL,
    pct_area_ndvi_gt_thr NVARCHAR(MAX) NULL,
    veg_density_mean NVARCHAR(MAX) NULL,
    fuel_index NVARCHAR(MAX) NULL,

    -- Ligações Externas
    external_fire_id NVARCHAR(MAX) NULL,

    -- Metadados de Ingestão
    load_file NVARCHAR(MAX) NULL,
    load_datetime DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_dsa_vegetation PRIMARY KEY CLUSTERED (id)
);
END