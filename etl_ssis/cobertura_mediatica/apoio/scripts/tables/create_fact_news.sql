/* 
   Ficheiro: 6_create_fact_news.sql
   Descrição: Criação da tabela de factos de Notícias
   Executar na Base de Dados: [DW.TAAD]
*/

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'fact_news' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[fact_news] (
        [news_id] INT IDENTITY(1,1) NOT NULL,
        
        -- Dados Descritivos
        [title] NVARCHAR(MAX),
        [link] NVARCHAR(MAX),
        
        -- Chaves Estrangeiras (FKs) para Dimensões
        [date_id] INT,
        [source_id] INT,
        [sentiment_id] INT,
        
        -- Métricas (Measures)
        [risk_score] INT,
        
        -- Campos de Array do DBML (Mapeados para JSON/Texto no SQL Server)
        [keywords] NVARCHAR(MAX), -- Armazenar como JSON ou CSV
        [entities] NVARCHAR(MAX), -- Armazenar como JSON ou CSV

        -- Auditoria
        [ingestion_date] DATETIME2(3) DEFAULT SYSUTCDATETIME(),

        CONSTRAINT [PK_fact_news] PRIMARY KEY CLUSTERED ([news_id])
    );

    -- Criar Relações (Foreign Keys)
    
    -- Relacionamento com dim_date
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_fact_news_dim_date')
    BEGIN
        ALTER TABLE [dbo].[fact_news] WITH CHECK ADD CONSTRAINT [FK_fact_news_dim_date] 
        FOREIGN KEY([date_id]) REFERENCES [dbo].[dim_date] ([date_id]);
    END

    -- Relacionamento com dim_source
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_fact_news_dim_source')
    BEGIN
        ALTER TABLE [dbo].[fact_news] WITH CHECK ADD CONSTRAINT [FK_fact_news_dim_source] 
        FOREIGN KEY([source_id]) REFERENCES [dbo].[dim_source] ([source_id]);
    END

    -- Relacionamento com dim_sentiment
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_fact_news_dim_sentiment')
    BEGIN
        ALTER TABLE [dbo].[fact_news] WITH CHECK ADD CONSTRAINT [FK_fact_news_dim_sentiment] 
        FOREIGN KEY([sentiment_id]) REFERENCES [dbo].[dim_sentiment] ([sentiment_id]);
    END
END