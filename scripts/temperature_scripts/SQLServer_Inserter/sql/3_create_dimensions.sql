IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.dim_day') AND type = N'U')
BEGIN
    CREATE TABLE dbo.dim_day (
        day_id INT NOT NULL, -- ID inteligente: AAAAMMDD (ex: 20250211)
        day INT NULL,
        month INT NULL,
        year INT NULL,
        week INT NULL,
        season NVARCHAR(50) NULL,
        weekday NVARCHAR(50) NULL,
        CONSTRAINT PK_dim_day PRIMARY KEY CLUSTERED (day_id)
    );
END

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.dim_location') AND type = N'U')
BEGIN
    CREATE TABLE dbo.dim_location (
        location_id INT IDENTITY(1,1) NOT NULL, -- Surrogate Key Auto-incremental
        district NVARCHAR(200) NULL,
        municipality NVARCHAR(200) NULL,
        parish NVARCHAR(200) NULL,
        nuts3 NVARCHAR(100) NULL,
        CONSTRAINT PK_dim_location PRIMARY KEY CLUSTERED (location_id)
    );
END