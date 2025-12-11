/*
    Script: 8_populate_dim_source.sql
    Objetivo: Povoar a dimensão de fontes (source) baseada na staging de notícias.
    Executar na Base de Dados: [DW.TAAD]
*/

-- 1. Inserir registo "Desconhecido" (-1) caso não exista
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_source] WHERE source_id = -1)
BEGIN
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_source] ON;
    
    INSERT INTO [DW.TAAD].[dbo].[dim_source] (source_id, source_name, country)
    VALUES (-1, N'DESCONHECIDO', N'DESCONHECIDO');
    
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_source] OFF;
END

-- 2. Inserir novas fontes provenientes da Staging
INSERT INTO [DW.TAAD].[dbo].[dim_source] (source_name, country)
SELECT DISTINCT
    -- Normalização do nome da fonte
    TRIM(UPPER(COALESCE(src.source, N'DESCONHECIDO'))) AS source_name,
    
    -- Como a staging não tem país, assumimos 'PORTUGAL' pelo contexto dos dados.
    -- Altere para N'DESCONHECIDO' se preferir não assumir o país.
    N'PORTUGAL' AS country

FROM [DSA.TAAD].[dbo].[stg_news] src
WHERE src.source IS NOT NULL
  AND NOT EXISTS (
    -- Evitar duplicados verificando pelo nome da fonte
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_source] tgt 
    WHERE tgt.source_name = TRIM(UPPER(COALESCE(src.source, N'DESCONHECIDO')))
);