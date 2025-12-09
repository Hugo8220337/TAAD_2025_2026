/*
    Script: populate_dim_day.sql
    Objetivo: Ler datas da Staging, limpar, gerar ID AAAAMMDD e inserir na dimensão.
    CORREÇÃO: Adicionado prefixo N'...' para suportar acentos (Unicode).
*/

WITH RawDates AS (
    SELECT DISTINCT TRY_CAST(DATAALERTA AS DATE) as CleanDate 
    FROM [dbo].[dsa_icnf_fire] -- Tabela Local
    WHERE DATAALERTA IS NOT NULL AND TRY_CAST(DATAALERTA AS DATE) IS NOT NULL
    UNION 
    SELECT DISTINCT TRY_CAST(DATAEXTINCAO AS DATE) 
    FROM [dbo].[dsa_icnf_fire]
    WHERE DATAEXTINCAO IS NOT NULL AND TRY_CAST(DATAEXTINCAO AS DATE) IS NOT NULL
    UNION
    SELECT DISTINCT TRY_CAST(DATA1INTERVENCAO AS DATE) 
    FROM [dbo].[dsa_icnf_fire]
    WHERE DATA1INTERVENCAO IS NOT NULL AND TRY_CAST(DATA1INTERVENCAO AS DATE) IS NOT NULL
),
CalculatedDays AS (
    SELECT 
        CleanDate,
        (YEAR(CleanDate) * 10000) + (MONTH(CleanDate) * 100) + DAY(CleanDate) AS day_id,
        DAY(CleanDate) AS [day],
        MONTH(CleanDate) AS [month],
        YEAR(CleanDate) AS [year],
        DATEPART(WEEK, CleanDate) AS [week],
        DATENAME(WEEKDAY, CleanDate) AS [weekday],
        CASE 
            WHEN MONTH(CleanDate) IN (3, 4, 5) THEN N'Primavera'
            WHEN MONTH(CleanDate) IN (6, 7, 8) THEN N'Verão'
            WHEN MONTH(CleanDate) IN (9, 10, 11) THEN N'Outono'
            ELSE N'Inverno'
        END AS season
    FROM RawDates
)
INSERT INTO [DW.TAAD].[dbo].[dim_day] (day_id, day, month, year, week, season, weekday)
SELECT day_id, [day], [month], [year], [week], season, [weekday]
FROM CalculatedDays src
WHERE NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_day] tgt WHERE tgt.day_id = src.day_id);

-- Inserir Desconhecido (-1)
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_day] WHERE day_id = -1)
BEGIN
    INSERT INTO [DW.TAAD].[dbo].[dim_day] (day_id, day, month, year, week, season, weekday)
    VALUES (-1, NULL, NULL, NULL, NULL, N'Desconhecido', N'Desconhecido');
END