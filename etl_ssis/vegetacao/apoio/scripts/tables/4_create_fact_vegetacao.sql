/* 
   Ficheiro: create_fact_vegetation.sql
   Executar na Base de Dados: [DW.TAAD]
*/

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'fact_vegetation' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[fact_vegetation] (
        -- Chave Primária (Surrogate Key)
        [veg_fact_id] INT IDENTITY(1,1) NOT NULL, 
        
        -- Chaves Estrangeiras (FKs) para as Dimensões
        [day_id] INT NOT NULL,          -- Liga a dim_day
        [location_id] INT NOT NULL,     -- Liga a dim_location
        [landcover_id] INT NOT NULL,    -- Liga a dim_landcover
        [species_id] INT NOT NULL,      -- Liga a dim_species

        -- Atributos Degenerados / Ligações Soltas
        [time_window] NVARCHAR(50),     -- Ex: 'pre_30', 'annual_2023'
        [external_fire_id] NVARCHAR(100), -- Ligação visual ao dataset de fogos (Sem FK física)

        -- Métricas (Measures)
        [area_m2] FLOAT,
        [ndvi_mean] FLOAT,
        [ndvi_median] FLOAT,
        [ndvi_std] FLOAT,
        [ndvi_count] INT,
        [pct_area_ndvi_gt_thr] FLOAT,
        [veg_density_mean] FLOAT,
        [fuel_index] FLOAT,

        -- Auditoria
        [processing_date] DATETIME2(3) DEFAULT SYSUTCDATETIME(),

        CONSTRAINT [PK_fact_vegetation] PRIMARY KEY CLUSTERED ([veg_fact_id])
    );

    -- Criar Relações (Foreign Keys)
    
    -- 1. Relação com Tempo
    ALTER TABLE [dbo].[fact_vegetation] WITH CHECK ADD CONSTRAINT [FK_fact_vegetation_dim_day] 
    FOREIGN KEY([day_id]) REFERENCES [dbo].[dim_day] ([day_id]);

    -- 2. Relação com Localização
    ALTER TABLE [dbo].[fact_vegetation] WITH CHECK ADD CONSTRAINT [FK_fact_vegetation_dim_location] 
    FOREIGN KEY([location_id]) REFERENCES [dbo].[dim_location] ([location_id]);

    -- 3. Relação com Ocupação do Solo
    ALTER TABLE [dbo].[fact_vegetation] WITH CHECK ADD CONSTRAINT [FK_fact_vegetation_dim_landcover] 
    FOREIGN KEY([landcover_id]) REFERENCES [dbo].[dim_landcover] ([landcover_id]);

    -- 4. Relação com Espécies
    ALTER TABLE [dbo].[fact_vegetation] WITH CHECK ADD CONSTRAINT [FK_fact_vegetation_dim_species] 
    FOREIGN KEY([species_id]) REFERENCES [dbo].[dim_species] ([species_id]);

END