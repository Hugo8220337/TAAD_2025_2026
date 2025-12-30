/* Ficheiro: vegetacao_staging.sql
   Objetivo: Criar tabela de staging com colunas iguais ao CSV 'ndvi_by_fire_2024.csv'
*/

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.dsa_vegetation') AND type = N'U')
BEGIN
CREATE TABLE dbo.dsa_vegetation (
    id INT IDENTITY(1,1) NOT NULL,

    -- Colunas exatas do CSV
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

    -- Metadados de sistema
    load_datetime DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_dsa_vegetation PRIMARY KEY CLUSTERED (id)
);
END