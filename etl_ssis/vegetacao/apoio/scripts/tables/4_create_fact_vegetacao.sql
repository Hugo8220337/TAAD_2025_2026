/* Ficheiro: create_fact_vegetation.sql
   Objetivo: Tabela de factos ajustada à realidade dos dados disponíveis
*/

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'fact_vegetation' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[fact_vegetation] (
        [veg_fact_id] INT IDENTITY(1,1) NOT NULL, 
        
        -- Chaves (Ligam às dimensões existentes)
        [day_id] INT NOT NULL,          -- Derivado de 't0'
        [location_id] INT NOT NULL,     -- Derivado de 'fire_id' (via fact_fire)

        -- Contexto
        [time_window] NVARCHAR(50),     -- Vem de 'time_window'
        [external_fire_id] NVARCHAR(100), -- Vem de 'fire_id'

        -- Métricas Disponíveis no CSV
        [area_m2] FLOAT,                -- Convertido de 'area_ha'
        [ndvi_mean] FLOAT,              -- Vem de 'ndvi_mean'
        [ndvi_std] FLOAT,               -- Vem de 'ndvi_std'
        [ndvi_count] INT,               -- Vem de 'ndvi_count'
        [pct_area_ndvi_gt_thr] FLOAT,   -- Vem de 'pct_area_ndvi_gt_thr'

        -- Auditoria
        [processing_date] DATETIME2(3) DEFAULT SYSUTCDATETIME(),

        CONSTRAINT [PK_fact_vegetation] PRIMARY KEY CLUSTERED ([veg_fact_id])
    );

    -- Foreign Keys
    ALTER TABLE [dbo].[fact_vegetation] WITH CHECK ADD CONSTRAINT [FK_fact_vegetation_dim_day] 
    FOREIGN KEY([day_id]) REFERENCES [dbo].[dim_day] ([day_id]);

    ALTER TABLE [dbo].[fact_vegetation] WITH CHECK ADD CONSTRAINT [FK_fact_vegetation_dim_location] 
    FOREIGN KEY([location_id]) REFERENCES [dbo].[dim_location] ([location_id]);
END