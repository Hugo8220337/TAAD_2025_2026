/*
    Script: populate_dim_day.sql (Correção FK)
    Objetivo: Incluir datas reconstruídas (Ano/Mes/Dia) para evitar falhas de chave estrangeira.
*/

WITH RawDates AS (
    -- 1. Datas standard (já tinhas)
    SELECT DISTINCT TRY_CAST(DATAALERTA AS DATE) as CleanDate FROM dbo.dsa_icnf_fire
    UNION 
    SELECT DISTINCT TRY_CAST(DATAEXTINCAO AS DATE) FROM dbo.dsa_icnf_fire
    UNION
    SELECT DISTINCT TRY_CAST(DATA1INTERVENCAO AS DATE) FROM dbo.dsa_icnf_fire
    UNION
    SELECT DISTINCT TRY_CAST(DHINICIO AS DATE) FROM dbo.dsa_icnf_fire
    UNION
    SELECT DISTINCT TRY_CAST(DHFIM AS DATE) FROM dbo.dsa_icnf_fire
    
    UNION
    -- 2. NOVAS DATAS (Reconstruídas de ANO, MES, DIA)
    -- Isto é essencial porque o fact_fire usa este fallback
    SELECT DISTINCT 
        TRY_CAST(CONCAT(ANO, '-', MES, '-', DIA) AS DATE)
    FROM dbo.dsa_icnf_fire
    WHERE TRY_CAST(CONCAT(ANO, '-', MES, '-', DIA) AS DATE) IS NOT NULL
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
            WHEN MONTH(CleanDate) IN (6, 7, 8) THEN N'Ver' + NCHAR(227) + N'o'
            WHEN MONTH(CleanDate) IN (9, 10, 11) THEN N'Outono'
            ELSE N'Inverno'
        END AS season
    FROM RawDates
    WHERE CleanDate IS NOT NULL
)
INSERT INTO [DW.TAAD].[dbo].[dim_day] (day_id, day, month, year, week, season, weekday)
SELECT day_id, [day], [month], [year], [week], season, [weekday]
FROM CalculatedDays src
WHERE NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_day] tgt WHERE tgt.day_id = src.day_id);

-- Garantir o ID -1 (Desconhecido)
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_day] WHERE day_id = -1)
BEGIN
    INSERT INTO [DW.TAAD].[dbo].[dim_day] (day_id, day, month, year, week, season, weekday)
    VALUES (-1, NULL, NULL, NULL, NULL, N'Desconhecido', N'Desconhecido');
END