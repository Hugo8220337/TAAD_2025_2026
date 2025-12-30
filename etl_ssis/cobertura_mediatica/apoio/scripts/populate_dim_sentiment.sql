/*
    Script: 7_populate_dim_sentiment.sql
    Objetivo: Povoar a dimensão de sentimento com base nos dados únicos da staging de notícias.
    Executar na Base de Dados: [DW.TAAD]
*/

-- 1. Inserir registo "Desconhecido" (-1) caso não exista
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_sentiment] WHERE sentiment_id = -1)
BEGIN
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_sentiment] ON;
    
    INSERT INTO [DW.TAAD].[dbo].[dim_sentiment] (sentiment_id, sentiment, polarity)
    VALUES (-1, 'DESCONHECIDO', 0);
    
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_sentiment] OFF;
END

-- 2. Inserir novos sentimentos provenientes da Staging
INSERT INTO [DW.TAAD].[dbo].[dim_sentiment] (sentiment, polarity)
SELECT DISTINCT
    -- Normalização do texto (Ex: 'positivo' -> 'POSITIVO')
    TRIM(UPPER(COALESCE(src.sentiment, 'DESCONHECIDO'))) AS sentiment,
    
    -- Derivação da Polaridade baseada no texto
    CASE 
        WHEN TRIM(LOWER(src.sentiment)) = 'positivo' THEN 1
        WHEN TRIM(LOWER(src.sentiment)) = 'negativo' THEN -1
        ELSE 0 -- 'neutro' ou outros valores assumem 0
    END AS polarity

FROM [DSA.TAAD].[dbo].[stg_news] src
WHERE src.sentiment IS NOT NULL
  AND NOT EXISTS (
    -- Evitar duplicados verificando se o sentimento já existe na dimensão
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_sentiment] tgt 
    WHERE tgt.sentiment = TRIM(UPPER(COALESCE(src.sentiment, 'DESCONHECIDO')))
);