/*
    Script: populate_dim_day.sql
    Objetivo: Ler day_id da Staging de vegetação, calcular atributos temporais e inserir na dimensão.
    Origem: [DSA.TAAD].[dbo].[dsa_vegetation]
    Destino: [DW.TAAD].[dbo].[dim_day]
*/

WITH RawDates AS (
    -- Converte o day_id (ex: '20250211') para DATA para permitir cálculos
    -- Assume-se que o formato na staging permite CAST direto ou via formato 112 (ISO)
    SELECT DISTINCT 
        TRY_CAST(day_id AS DATE) as CleanDate 
    FROM [DSA.TAAD].[dbo].[dsa_vegetation]
    WHERE day_id IS NOT NULL 
      AND TRY_CAST(day_id AS DATE) IS NOT NULL
),
CalculatedDays AS (
    SELECT 
        -- Recalcula o ID numérico AAAAMMDD para garantir consistência
        (YEAR(CleanDate) * 10000) + (MONTH(CleanDate) * 100) + DAY(CleanDate) AS day_id,
        DAY(CleanDate) AS [day],
        MONTH(CleanDate) AS [month],
        YEAR(CleanDate) AS [year],
        DATEPART(WEEK, CleanDate) AS [week],
        DATENAME(WEEKDAY, CleanDate) AS [weekday],
        CASE 
            WHEN MONTH(CleanDate) IN (3, 4, 5) THEN N'Primavera'
            -- N'Ver' + NCHAR(227) + N'o' para gerar "Verão" sem problemas de encoding
            WHEN MONTH(CleanDate) IN (6, 7, 8) THEN N'Ver' + NCHAR(227) + N'o'
            WHEN MONTH(CleanDate) IN (9, 10, 11) THEN N'Outono'
            ELSE N'Inverno'
        END AS season
    FROM RawDates
)
INSERT INTO [DW.TAAD].[dbo].[dim_day] (day_id, day, month, year, week, season, weekday)
SELECT day_id, [day], [month], [year], [week], season, [weekday]
FROM CalculatedDays src
WHERE NOT EXISTS (
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_day] tgt WHERE tgt.day_id = src.day_id
);

-- Garantir registo 'Desconhecido' (-1)
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_day] WHERE day_id = -1)
BEGIN
    INSERT INTO [DW.TAAD].[dbo].[dim_day] (day_id, day, month, year, week, season, weekday)
    VALUES (-1, NULL, NULL, NULL, NULL, N'Desconhecido', N'Desconhecido');
END