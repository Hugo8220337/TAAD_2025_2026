IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.fact_daily_meteorology') AND type = N'U')
BEGIN
    CREATE TABLE dbo.fact_daily_meteorology (
        id INT IDENTITY(1,1) NOT NULL,

        -- Chaves Estrangeiras (Dimensões)
        day_id INT NOT NULL,
        location_id INT NOT NULL,

        -- Métricas de Temperatura
        temp_max FLOAT NULL,
        temp_min FLOAT NULL,
        temp_mean FLOAT NULL, -- temperatura média

        -- Métricas de Humidade
        rh_max FLOAT NULL,
        rh_min FLOAT NULL,
        rh_mean FLOAT NULL, -- humidade relativa média

        -- Métricas de Precipitação
        precip_sum FLOAT NULL,
        rain_sum FLOAT NULL,
        precip_hours INT NULL,

        -- Métricas de Vento
        wind_max FLOAT NULL,
        gust_max FLOAT NULL,
        wind_dir FLOAT NULL,
        wind_speed_mean FLOAT NULL, -- velocidade média do vento

        -- Radiação e Insolação
        radiation FLOAT NULL,
        sunshine FLOAT NULL,
        shortwave_radiation FLOAT NULL, -- radiação de onda curta

        -- Evapotranspiração
        et0 FLOAT NULL,

        -- Pressão e Nuvens
        pressure_msl FLOAT NULL, -- pressão ao nível do mar
        cloud_cover FLOAT NULL,  -- cobertura de nuvens (%)

        -- Índices Derivados (Flags Booleanas e Índices)
        is_dry_day BIT NULL,          -- dia seco
        is_high_wind_day BIT NULL,    -- dia de vento forte
        fire_weather_index FLOAT NULL, -- índice FWI

        -- Metadados de carga (Opcional, mas recomendado)
        load_datetime DATETIME2(3) DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_fact_daily_meteorology PRIMARY KEY CLUSTERED (id)
    );

    -- Definição das Foreign Keys
    ALTER TABLE dbo.fact_daily_meteorology
        ADD CONSTRAINT FK_fact_meteorology_day FOREIGN KEY (day_id) REFERENCES dbo.dim_day(day_id);

    ALTER TABLE dbo.fact_daily_meteorology
        ADD CONSTRAINT FK_fact_meteorology_location FOREIGN KEY (location_id) REFERENCES dbo.dim_location(location_id);
END