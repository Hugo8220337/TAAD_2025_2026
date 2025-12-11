/*
    Script: 10_populate_fact_news.sql
    Objetivo: Carregar a tabela de factos de Notícias transformando chaves de negócio em IDs das dimensões.
    Executar na Base de Dados: [DW.TAAD]
*/

INSERT INTO [DW.TAAD].[dbo].[fact_news] (
    title,
    link,
    
    -- Chaves das Dimensões
    date_id,
    source_id,
    sentiment_id,
    
    -- Métricas e Atributos
    risk_score,
    keywords,
    entities,
    
    -- Auditoria
    ingestion_date
)
SELECT 
    src.title,
    src.link,

    -------------------------------------------------------
    -- 1. CALCULO DA DATA (Formato AAAAMMDD)
    -------------------------------------------------------
    COALESCE(
        (YEAR(TRY_CAST(src.[date] AS DATE)) * 10000) + 
        (MONTH(TRY_CAST(src.[date] AS DATE)) * 100) + 
        DAY(TRY_CAST(src.[date] AS DATE)), 
    -1) AS date_id,

    -------------------------------------------------------
    -- 2. LOOKUPS PARA AS DIMENSÕES (Joins)
    -------------------------------------------------------
    
    -- Fonte: Se não encontrar, usa -1 (Desconhecido)
    COALESCE(ds.source_id, -1) AS source_id,
    
    -- Sentimento: Se não encontrar, usa -1 (Desconhecido)
    COALESCE(dsem.sentiment_id, -1) AS sentiment_id,

    -------------------------------------------------------
    -- 3. MÉTRICAS E DADOS BRUTOS
    -------------------------------------------------------
    TRY_CAST(src.risk_score AS INT) AS risk_score,
    
    -- Mantemos keywords e entities como texto (JSON) conforme vieram da staging
    src.keywords,
    src.entities,
    
    -- Data de inserção atual
    SYSUTCDATETIME() AS ingestion_date

FROM [DSA.TAAD].[dbo].[stg_news] src

-- JOIN DIMENSÃO FONTE (Normalizando texto)
LEFT JOIN [DW.TAAD].[dbo].[dim_source] ds ON 
    ds.source_name = TRIM(UPPER(COALESCE(src.source, N'DESCONHECIDO')))

-- JOIN DIMENSÃO SENTIMENTO (Normalizando texto)
LEFT JOIN [DW.TAAD].[dbo].[dim_sentiment] dsem ON 
    dsem.sentiment = TRIM(UPPER(COALESCE(src.sentiment, N'DESCONHECIDO')))

WHERE 
    -- Evitar duplicados verificando pelo Link (que deve ser único por notícia)
    NOT EXISTS (
        SELECT 1 FROM [DW.TAAD].[dbo].[fact_news] tgt 
        WHERE tgt.link = src.link
    );