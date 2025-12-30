/* 
   Ficheiro: 4_create_fact_meteorology.sql
   Executar na Base de Dados: [DW.TAAD]
*/

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'fact_daily_meteorology' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[fact_daily_meteorology] (
        [id] INT IDENTITY(1,1) NOT NULL, -- Surrogate Key (Auto-increment)

        -- Chaves Estrangeiras (Dimensões)
        [day_id] INT NOT NULL,
        [location_id] INT NOT NULL,

        -- Métricas de Temperatura
        [temp_max] FLOAT,
        [temp_min] FLOAT,
        [temp_mean] FLOAT, 
        
        -- Métricas de Humidade
        [rh_max] FLOAT,
        [rh_min] FLOAT,
        [rh_mean] FLOAT,
        
        -- Métricas de Precipitação
        [precip_sum] FLOAT,
        [rain_sum] FLOAT,
        [precip_hours] INT,
        
        -- Métricas de Vento
        [wind_max] FLOAT,
        [gust_max] FLOAT,
        [wind_dir] FLOAT,
        [wind_speed_mean] FLOAT,
        
        -- Radiação e Insolação
        [radiation] FLOAT,
        [sunshine] FLOAT,
        [shortwave_radiation] FLOAT,
        
        -- Evapotranspiração
        [et0] FLOAT,
        
        -- Pressão e Nuvens
        [pressure_msl] FLOAT,
        [cloud_cover] FLOAT,
        
        -- Índices Derivados (Flags Booleanas e Índices)
        [is_dry_day] BIT,          -- DBML boolean -> SQL BIT
        [is_high_wind_day] BIT,    -- DBML boolean -> SQL BIT
        [fire_weather_index] FLOAT,

        -- Auditoria
        [processing_date] DATETIME2(3) DEFAULT SYSUTCDATETIME(),

        CONSTRAINT [PK_fact_daily_meteorology] PRIMARY KEY CLUSTERED ([id])
    );

    -- Criar Relações (Foreign Keys)
    -- Garante que o dia existe na dimensão partilhada
    ALTER TABLE [dbo].[fact_daily_meteorology] WITH CHECK 
        ADD CONSTRAINT [FK_fact_meteo_dim_day] FOREIGN KEY([day_id]) 
        REFERENCES [dbo].[dim_day] ([day_id]);

    -- Garante que a localização existe na dimensão partilhada
    ALTER TABLE [dbo].[fact_daily_meteorology] WITH CHECK 
        ADD CONSTRAINT [FK_fact_meteo_dim_location] FOREIGN KEY([location_id]) 
        REFERENCES [dbo].[dim_location] ([location_id]);
END