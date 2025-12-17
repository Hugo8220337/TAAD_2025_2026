/*
    Script: populate_dim_day.sql
    Objetivo: Ler o campo 't0' (data) da Staging de vegetação, calcular atributos temporais e inserir na dimensão.
    Origem: [DSA.TAAD].[dbo].[dsa_vegetation]
    Destino: [DW.TAAD].[dbo].[dim_day]
*/

WITH RawDates AS (
    -- 1. Extrair datas únicas da coluna t0 (formato esperado: 'YYYY-MM-DD')
    SELECT DISTINCT 
        TRY_CAST(t0 AS DATE) as CleanDate 
    FROM [DSA.TAAD].[dbo].[dsa_vegetation]
    WHERE t0 IS NOT NULL 
      AND TRY_CAST(t0 AS DATE) IS NOT NULL
),
CalculatedDays AS (
    SELECT 
        -- 2. Gerar o ID numérico (Surrogate Key) no formato AAAAMMDD
        (YEAR(CleanDate) * 10000) + (MONTH(CleanDate) * 100) + DAY(CleanDate) AS day_id,
        
        -- 3. Calcular atributos derivados
        DAY(CleanDate) AS [day],
        MONTH(CleanDate) AS [month],
        YEAR(CleanDate) AS [year],
        DATEPART(WEEK, CleanDate) AS [week],
        DATENAME(WEEKDAY, CleanDate) AS [weekday],
        
        -- 4. Lógica das Estações do Ano
        CASE 
            WHEN MONTH(CleanDate) IN (3, 4, 5) THEN N'Primavera'
            -- N'Ver' + NCHAR(227) + N'o' = "Verão" (evita problemas de encoding)
            WHEN MONTH(CleanDate) IN (6, 7, 8) THEN N'Ver' + NCHAR(227) + N'o'
            WHEN MONTH(CleanDate) IN (9, 10, 11) THEN N'Outono'
            ELSE N'Inverno'
        END AS season
    FROM RawDates
)
-- 5. Inserir na dimensão apenas se o day_id ainda não existir
INSERT INTO [DW.TAAD].[dbo].[dim_day] (day_id, day, month, year, week, season, weekday)
SELECT day_id, [day], [month], [year], [week], season, [weekday]
FROM CalculatedDays src
WHERE NOT EXISTS (
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_day] tgt 
    WHERE tgt.day_id = src.day_id
);

-- 6. Garantir registo 'Desconhecido' (-1) para tratar falhas de lookup
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_day] WHERE day_id = -1)
BEGIN
    INSERT INTO [DW.TAAD].[dbo].[dim_day] (day_id, day, month, year, week, season, weekday)
    VALUES (-1, NULL, NULL, NULL, NULL, N'Desconhecido', N'Desconhecido');
END