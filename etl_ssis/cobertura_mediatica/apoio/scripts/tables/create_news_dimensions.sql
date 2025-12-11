/*
   Ficheiro: 5_create_news_dimensions.sql
   Descrição: Criação das dimensões para o esquema de Notícias (News)
   Executar na Base de Dados: [DW.TAAD]
*/

-- 1. Dimensão Data (Específica para Notícias, conforme DBML)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_date' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_date] (
        [date_id] INT NOT NULL, -- Ex: 20231215
        [date] DATE,
        [year] INT,
        [month] INT,
        [month_name] NVARCHAR(50),
        [day] INT,
        [weekday] NVARCHAR(50),
        CONSTRAINT [PK_dim_date] PRIMARY KEY CLUSTERED ([date_id])
    );
END

-- 2. Dimensão Fonte (Source)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_source' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_source] (
        [source_id] INT IDENTITY(1,1) NOT NULL,
        [source_name] NVARCHAR(255),
        [country] NVARCHAR(100),
        CONSTRAINT [PK_dim_source] PRIMARY KEY CLUSTERED ([source_id])
    );
END

-- 3. Dimensão Sentimento
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_sentiment' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[dim_sentiment] (
        [sentiment_id] INT IDENTITY(1,1) NOT NULL,
        [sentiment] NVARCHAR(50), -- Ex: 'Positive', 'Negative'
        [polarity] INT,           -- Ex: 1, -1, 0
        CONSTRAINT [PK_dim_sentiment] PRIMARY KEY CLUSTERED ([sentiment_id])
    );
END