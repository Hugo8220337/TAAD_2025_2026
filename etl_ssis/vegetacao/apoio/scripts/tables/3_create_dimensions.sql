/* Ficheiro: 3_create_dimensions_simple.sql
   Executar na Base de Dados: [DW.TAAD]
   Nota: As dimensões dim_landcover e dim_species foram removidas.
*/

-- 1. Dimensão Dia
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_day' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_day] (
        [day_id] INT NOT NULL, -- Formato AAAAMMDD
        [day] INT,
        [month] INT,
        [year] INT,
        [week] INT,
        [season] NVARCHAR(50),
        [weekday] NVARCHAR(50), 
        CONSTRAINT [PK_dim_day] PRIMARY KEY CLUSTERED ([day_id])
    );
END

-- 2. Dimensão Localização
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_location' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_location] (
        [location_id] INT IDENTITY(1,1) NOT NULL,
        [district] NVARCHAR(200),     
        [municipality] NVARCHAR(200), 
        [parish] NVARCHAR(200),       
        [nuts3] NVARCHAR(50),         
        CONSTRAINT [PK_dim_location] PRIMARY KEY CLUSTERED ([location_id])
    );
END