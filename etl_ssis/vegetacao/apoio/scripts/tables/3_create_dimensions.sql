/* 
   Ficheiro: create_vegetation_dimensions.sql
   Executar na Base de Dados: [DW.TAAD]
*/

-- 1. Dimensão Dia (Já existente no script anterior, mantida para consistência com o DBML)
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

-- 2. Dimensão Localização (Já existente no script anterior, mantida para consistência com o DBML)
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

-- 3. Dimensão Ocupação do Solo (Nova tabela baseada no DBML)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_landcover' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_landcover] (
        [landcover_id] INT IDENTITY(1,1) NOT NULL,
        [corine_code] INT,
        [corine_description] NVARCHAR(MAX), -- NVARCHAR para descrições longas e acentos
        [fuel_category] NVARCHAR(100),      -- ex: 'Forest', 'Shrub'
        [typical_fuel_load] FLOAT,          -- Carga de combustível típica
        [dominant_species_hint] NVARCHAR(200), -- Dica da espécie dominante
        CONSTRAINT [PK_dim_landcover] PRIMARY KEY CLUSTERED ([landcover_id])
    );
END

-- 4. Dimensão Espécies (Nova tabela baseada no DBML)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_species' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_species] (
        [species_id] INT IDENTITY(1,1) NOT NULL,
        [species_name] NVARCHAR(200),       -- Nome da espécie
        [flammability_score] FLOAT,         -- Score de inflamabilidade
        CONSTRAINT [PK_dim_species] PRIMARY KEY CLUSTERED ([species_id])
    );
END