/* 
   Script: populate_dim_day_meteo.sql
   Executar na conexão: [DSA.TAAD]
   Objetivo: Ler datas da Staging de Meteorologia e povoar a dimensão dia na DW.
*/

-- 1. CTE para buscar todas as datas únicas da meteorologia (convertendo texto para data)
WITH MeteoDates AS (
    SELECT DISTINCT 
        TRY_CAST([date] AS DATE) as CleanDate
    FROM [dbo].[dsa_meteorology] -- Tabela Local (Staging)
    WHERE [date] IS NOT NULL AND TRY_CAST([date] AS DATE) IS NOT NULL
),

-- 2. Calcular atributos (Ano, Mês, Dia, ID)
CalculatedDays AS (
    SELECT 
        CleanDate,
        -- Gerar ID AAAAMMDD (Ex: 20200503)
        (YEAR(CleanDate) * 10000) + (MONTH(CleanDate) * 100) + DAY(CleanDate) AS day_id,
        DAY(CleanDate) AS [day],
        MONTH(CleanDate) AS [month],
        YEAR(CleanDate) AS [year],
        DATEPART(WEEK, CleanDate) AS [week],
        DATENAME(WEEKDAY, CleanDate) AS [weekday],
        
        -- Detalhe: Uso de N'' para garantir acentos corretos no NVARCHAR
        CASE 
            WHEN MONTH(CleanDate) IN (3, 4, 5) THEN N'Primavera'
            WHEN MONTH(CleanDate) IN (6, 7, 8) THEN N'Verão'
            WHEN MONTH(CleanDate) IN (9, 10, 11) THEN N'Outono'
            ELSE N'Inverno'
        END AS season
    FROM MeteoDates
)

-- 3. Inserir na Dimensão (DW) APENAS o que ainda não existe
INSERT INTO [DW.TAAD].[dbo].[dim_day] (day_id, day, month, year, week, season, weekday)
SELECT 
    day_id, [day], [month], [year], [week], season, [weekday]
FROM CalculatedDays src
WHERE NOT EXISTS (
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_day] tgt 
    WHERE tgt.day_id = src.day_id
);