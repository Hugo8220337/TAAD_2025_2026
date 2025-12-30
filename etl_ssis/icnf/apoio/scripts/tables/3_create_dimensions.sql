/* Ficheiro: 3_create_dimensions_dw.sql (Corrigido para NVARCHAR)
   Executar na Base de Dados: [DW.TAAD]
*/

-- 1. Dimensão Hora
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_hour' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_hour] (
        [hour_id] INT NOT NULL, 
        [hour] INT,
        [time_of_day] NVARCHAR(50),
        CONSTRAINT [PK_dim_hour] PRIMARY KEY CLUSTERED ([hour_id])
    );
END

-- 2. Dimensão Dia
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_day' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_day] (
        [day_id] INT NOT NULL,
        [day] INT,
        [month] INT,
        [year] INT,
        [week] INT,
        [season] NVARCHAR(50),
        [weekday] NVARCHAR(50), 
        CONSTRAINT [PK_dim_day] PRIMARY KEY CLUSTERED ([day_id])
    );
END

-- 3. Dimensão Localização
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

-- 4. Dimensão Tipo de Fogo
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_fire_type' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_fire_type] (
        [fire_type_id] INT IDENTITY(1,1) NOT NULL,
        [type_name] NVARCHAR(200), 
        [is_control_burn] BIT,
        [is_false_alarm] BIT,
        [is_agricultural] BIT,
        CONSTRAINT [PK_dim_fire_type] PRIMARY KEY CLUSTERED ([fire_type_id])
    );
END

-- 5. Dimensão Causa
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_cause' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_cause] (
        [cause_id] INT IDENTITY(1,1) NOT NULL,
        [cause_name] NVARCHAR(255),     
        [cause_category] NVARCHAR(255), 
        [cause_family] NVARCHAR(255),   
        CONSTRAINT [PK_dim_cause] PRIMARY KEY CLUSTERED ([cause_id])
    );
END