/* 
   Ficheiro: create_meteorology_dimensions.sql
   Executar na Base de Dados: [DW.TAAD]
*/

-- 1. Dimensão Dia (Time Dimension)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_day' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_day] (
        [day_id] INT NOT NULL,  -- aammdd (Ex: 20250211)
        [day] INT,
        [month] INT,
        [year] INT,
        [week] INT,
        [season] NVARCHAR(50),  -- NVARCHAR para 'Verão', 'Outono'
        [weekday] NVARCHAR(50), -- NVARCHAR para 'Sábado', 'Terça'
        CONSTRAINT [PK_dim_day] PRIMARY KEY CLUSTERED ([day_id])
    );
END

-- 2. Dimensão Localização (Geographic Dimension)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_location' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_location] (
        [location_id] INT IDENTITY(1,1) NOT NULL,
        [district] NVARCHAR(200),     -- NVARCHAR para acentos (Ex: 'Santarém')
        [municipality] NVARCHAR(200), -- NVARCHAR para acentos
        [parish] NVARCHAR(200),       -- NVARCHAR para acentos (Ex: 'Conceição')
        [nuts3] NVARCHAR(50),
        CONSTRAINT [PK_dim_location] PRIMARY KEY CLUSTERED ([location_id])
    );
END