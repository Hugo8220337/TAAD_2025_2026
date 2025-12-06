/*
    Script: populate_dim_day.sql
    Objetivo: Ler datas da Staging, limpar, gerar ID AAAAMMDD e inserir na dimensão.
    CORREÇÃO: Adicionado prefixo N'...' para suportar acentos (Unicode).
*/

-- 1. CTE para buscar TODAS as datas relevantes da staging (sem duplicados)
WITH RawDates AS (
    -- Data de Alerta
    SELECT DISTINCT 
        TRY_CAST(DATAALERTA AS DATE) as CleanDate
    FROM dbo.dsa_icnf_fire
    WHERE DATAALERTA IS NOT NULL AND TRY_CAST(DATAALERTA AS DATE) IS NOT NULL
    
    UNION 
    
    -- Data de Extinção
    SELECT DISTINCT 
        TRY_CAST(DATAEXTINCAO AS DATE)
    FROM dbo.dsa_icnf_fire
    WHERE DATAEXTINCAO IS NOT NULL AND TRY_CAST(DATAEXTINCAO AS DATE) IS NOT NULL

    UNION

    -- Data de 1ª Intervenção
    SELECT DISTINCT 
        TRY_CAST(DATA1INTERVENCAO AS DATE)
    FROM dbo.dsa_icnf_fire
    WHERE DATA1INTERVENCAO IS NOT NULL AND TRY_CAST(DATA1INTERVENCAO AS DATE) IS NOT NULL
),

-- 2. Calcular os atributos para cada data encontrada
CalculatedDays AS (
    SELECT 
        CleanDate,
        -- Gerar o ID no formato AAAAMMDD (Ex: 20250211)
        (YEAR(CleanDate) * 10000) + (MONTH(CleanDate) * 100) + DAY(CleanDate) AS day_id,
        DAY(CleanDate) AS [day],
        MONTH(CleanDate) AS [month],
        YEAR(CleanDate) AS [year],
        DATEPART(WEEK, CleanDate) AS [week],
        DATENAME(WEEKDAY, CleanDate) AS [weekday],
        
        -- Calcular Estação do Ano com prefixo N para acentos
        CASE 
            WHEN MONTH(CleanDate) IN (3, 4, 5) THEN N'Primavera'
            WHEN MONTH(CleanDate) IN (6, 7, 8) THEN N'Verão'
            WHEN MONTH(CleanDate) IN (9, 10, 11) THEN N'Outono'
            ELSE N'Inverno'
        END AS season
    FROM RawDates
)

-- 3. Inserir na Dimensão APENAS o que ainda não existe
INSERT INTO dbo.dim_day (day_id, day, month, year, week, season, weekday)
SELECT 
    day_id, 
    [day], 
    [month], 
    [year], 
    [week], 
    season, 
    [weekday]
FROM CalculatedDays src
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.dim_day tgt WHERE tgt.day_id = src.day_id
);

-- 4. Inserir registo de "Data Desconhecida" (-1)
IF NOT EXISTS (SELECT 1 FROM dbo.dim_day WHERE day_id = -1)
BEGIN
    INSERT INTO dbo.dim_day (day_id, day, month, year, week, season, weekday)
    VALUES (-1, NULL, NULL, NULL, NULL, N'Desconhecido', N'Desconhecido');
END