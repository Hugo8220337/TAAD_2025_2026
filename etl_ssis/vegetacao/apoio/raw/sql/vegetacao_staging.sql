IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.dsa_vegetation') AND type = N'U'
)
BEGIN
CREATE TABLE dbo.dsa_vegetation (
    -- ID sequencial para controlo interno
    id INT IDENTITY(1,1) NOT NULL,

    -- Colunas da Fonte de Dados (Raw)
    fire_id NVARCHAR(MAX) NULL,              -- Ligação ao fogo
    Ano NVARCHAR(MAX) NULL,                  -- Ano
    t0 NVARCHAR(MAX) NULL,                   -- Data de referência (provavelmente data do fogo)
    time_window NVARCHAR(MAX) NULL,          -- Janela temporal (ex: pre_30, post_90)
    
    -- Métricas de NDVI
    ndvi_mean NVARCHAR(MAX) NULL,
    ndvi_std NVARCHAR(MAX) NULL,
    ndvi_count NVARCHAR(MAX) NULL,
    pct_area_ndvi_gt_thr NVARCHAR(MAX) NULL, -- % Área acima do limiar
    
    -- Outras Métricas
    area_ha NVARCHAR(MAX) NULL,              -- Área em Hectares
    
    -- Auditoria da Fonte
    processing_date NVARCHAR(MAX) NULL,

    -- Metadados de Ingestão (Controlo do Processo)
    load_file NVARCHAR(MAX) NULL,
    load_datetime DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_dsa_vegetation PRIMARY KEY CLUSTERED (id)
);
END