/*
    Script: 9_populate_dim_date.sql
    Objetivo: Ler datas da Staging de Notícias, limpar, gerar ID AAAAMMDD e inserir na dimensão.
    Executar na Base de Dados: [DW.TAAD]
*/

WITH RawDates AS (
    -- Seleciona todas as datas únicas encontradas na tabela de staging de notícias
    SELECT DISTINCT TRY_CAST([date] AS DATE) as CleanDate 
    FROM [DSA.TAAD].[dbo].[stg_news]
    WHERE [date] IS NOT NULL AND TRY_CAST([date] AS DATE) IS NOT NULL
),
CalculatedDates AS (
    SELECT 
        CleanDate,
        -- Gerar ID no formato YYYYMMDD (Ex: 20231225)
        (YEAR(CleanDate) * 10000) + (MONTH(CleanDate) * 100) + DAY(CleanDate) AS date_id,
        DAY(CleanDate) AS [day],
        MONTH(CleanDate) AS [month],
        -- DATENAME devolve o nome (Ex: 'January' ou 'Janeiro' dependendo da linguagem do SQL Server)
        CAST(DATENAME(MONTH, CleanDate) AS NVARCHAR(50)) AS [month_name], 
        YEAR(CleanDate) AS [year],
        CAST(DATENAME(WEEKDAY, CleanDate) AS NVARCHAR(50)) AS [weekday]
    FROM RawDates
)
INSERT INTO [DW.TAAD].[dbo].[dim_date] (date_id, [date], [year], [month], [month_name], [day], [weekday])
SELECT 
    date_id, 
    CleanDate, 
    [year], 
    [month], 
    [month_name], 
    [day], 
    [weekday]
FROM CalculatedDates src
WHERE NOT EXISTS (
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_date] tgt 
    WHERE tgt.date_id = src.date_id
);

-- Inserir Registo "Desconhecido" (-1)
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_date] WHERE date_id = -1)
BEGIN
    INSERT INTO [DW.TAAD].[dbo].[dim_date] (date_id, [date], [year], [month], [month_name], [day], [weekday])
    VALUES (-1, NULL, NULL, NULL, N'Desconhecido', NULL, N'Desconhecido');
END