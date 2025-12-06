IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.dsa_meteorology') AND type = N'U'
)
BEGIN
CREATE TABLE dbo.dsa_meteorology (
    incident_id NVARCHAR(100) NOT NULL,
    source_file NVARCHAR(MAX) NULL,
    date NVARCHAR(20) NOT NULL, -- YYYY-MM-DD
    lat NVARCHAR(MAX) NULL,
    lon NVARCHAR(MAX) NULL,
    temp_max NVARCHAR(MAX) NULL,
    temp_min NVARCHAR(MAX) NULL,
    rh_max NVARCHAR(MAX) NULL,
    rh_min NVARCHAR(MAX) NULL,
    precip_sum NVARCHAR(MAX) NULL,
    rain_sum NVARCHAR(MAX) NULL,
    precip_hours NVARCHAR(MAX) NULL,
    wind_max NVARCHAR(MAX) NULL,
    gust_max NVARCHAR(MAX) NULL,
    wind_dir NVARCHAR(MAX) NULL,
    radiation NVARCHAR(MAX) NULL,
    sunshine NVARCHAR(MAX) NULL,
    et0 NVARCHAR(MAX) NULL,
    
    -- Campos de controlo de carga
    load_file NVARCHAR(MAX) NULL,
    load_datetime DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    -- Chave Primária Composta (Incêndio + Data)
    CONSTRAINT PK_dsa_meteorology PRIMARY KEY NONCLUSTERED (incident_id, date)
);
END