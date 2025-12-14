/* 
   Ficheiro: 4_create_fact_fire_dw.sql
   Executar na Base de Dados: [DW.TAAD]
*/

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'fact_fire' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[fact_fire] (
        [fire_id] VARCHAR(100) NOT NULL, -- Chave natural do ICNF
        
        -- Chaves Estrangeiras (FKs)
        [alert_hour_id] INT,
        [extinguish_hour_id] INT,
        [first_intervention_hour_id] INT,
        [start_day_id] INT,
        [end_day_id] INT,
        [location_id] INT,
        [fire_type_id] INT,
        [cause_id] INT,

        -- Métricas (Measures)
        [area_total_m2] FLOAT,
        [area_pov_m2] FLOAT,
        [area_shrub_m2] FLOAT,
        [area_agri_m2] FLOAT,
        [duration_hours] FLOAT,
        [perimeter_m] FLOAT,
        
        -- Dados Espaciais
        [latitude] FLOAT,
        [longitude] FLOAT,

        -- Contadores
        [ndays] INT,

        -- Auditoria
        [processing_date] DATETIME2(3) DEFAULT SYSUTCDATETIME(),

        CONSTRAINT [PK_fact_fire] PRIMARY KEY CLUSTERED ([fire_id])
    );

    -- Criar Relações (Foreign Keys)
    ALTER TABLE [dbo].[fact_fire] WITH CHECK ADD CONSTRAINT [FK_fact_fire_dim_hour_alert] FOREIGN KEY([alert_hour_id]) REFERENCES [dbo].[dim_hour] ([hour_id]);
    ALTER TABLE [dbo].[fact_fire] WITH CHECK ADD CONSTRAINT [FK_fact_fire_dim_day_start] FOREIGN KEY([start_day_id]) REFERENCES [dbo].[dim_day] ([day_id]);
    ALTER TABLE [dbo].[fact_fire] WITH CHECK ADD CONSTRAINT [FK_fact_fire_dim_location] FOREIGN KEY([location_id]) REFERENCES [dbo].[dim_location] ([location_id]);
    ALTER TABLE [dbo].[fact_fire] WITH CHECK ADD CONSTRAINT [FK_fact_fire_dim_cause] FOREIGN KEY([cause_id]) REFERENCES [dbo].[dim_cause] ([cause_id]);
    ALTER TABLE [dbo].[fact_fire] WITH CHECK ADD CONSTRAINT [FK_fact_fire_dim_type] FOREIGN KEY([fire_type_id]) REFERENCES [dbo].[dim_fire_type] ([fire_type_id]);
END