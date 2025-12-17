IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.dsa_vegetation_quarantine') AND type = N'U'
)
BEGIN
CREATE TABLE dbo.dsa_vegetation_quarantine (
    id INT IDENTITY(1,1) NOT NULL,

    -- Colunas da Fonte de Dados
    fire_id NVARCHAR(MAX) NULL,
    Ano NVARCHAR(MAX) NULL,
    t0 NVARCHAR(MAX) NULL,
    time_window NVARCHAR(MAX) NULL,
    ndvi_mean NVARCHAR(MAX) NULL,
    ndvi_std NVARCHAR(MAX) NULL,
    ndvi_count NVARCHAR(MAX) NULL,
    pct_area_ndvi_gt_thr NVARCHAR(MAX) NULL,
    area_ha NVARCHAR(MAX) NULL,
    processing_date NVARCHAR(MAX) NULL,

    -- Metadados de Ingestão
    load_file NVARCHAR(MAX) NULL,
    load_datetime DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_dsa_vegetation_quarantine PRIMARY KEY CLUSTERED (id)
);
END