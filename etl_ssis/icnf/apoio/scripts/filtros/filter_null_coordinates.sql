/*
    Script: filter_null_coordinates.sql
    Objetivo: Remover registos sem Latitude ou Longitude válidas.
*/

DELETE FROM dbo.dsa_icnf_fire
WHERE 
    -- 1. Verifica se é estritamente NULL
    LAT IS NULL 
    OR LON IS NULL
    
    -- 2. Verifica se está vazio (string vazia) ou tem apenas espaços
    OR TRIM(LAT) = '' 
    OR TRIM(LON) = ''
    
    -- 3. Verifica se é '0' (Muitas vezes usado como default de erro em sistemas antigos)
    OR LAT = '0'
    OR LON = '0';