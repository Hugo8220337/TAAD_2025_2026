/*
    Script: populate_dim_location.sql
    Objetivo: Povoar a dimensão localização com base nos dados únicos da staging.
    Nota: Usa IDENTITY_INSERT para forçar o ID -1 (Desconhecido).
*/

-- 1. Inserir registo de "Localização Desconhecida" (ID -1) se não existir
--    Precisamos de ligar o IDENTITY_INSERT porque a tabela tem auto-incremento
IF NOT EXISTS (SELECT 1 FROM dbo.dim_location WHERE location_id = -1)
BEGIN
    SET IDENTITY_INSERT dbo.dim_location ON;
    
    INSERT INTO dbo.dim_location (location_id, district, municipality, parish, nuts3)
    VALUES (-1, N'Desconhecido', N'Desconhecido', N'Desconhecido', NULL);
    
    SET IDENTITY_INSERT dbo.dim_location OFF;
END

-- 2. Selecionar combinações únicas da Staging Area
--    Usamos TRIM para limpar espaços e UPPER para evitar duplicados por minúsculas/maiúsculas
INSERT INTO dbo.dim_location (district, municipality, parish, nuts3)
SELECT DISTINCT
    -- Tratamento de NULLs com COALESCE para evitar erros
    TRIM(UPPER(COALESCE(DISTRITO, N'Desconhecido'))) AS district,
    TRIM(UPPER(COALESCE(CONCELHO, N'Desconhecido'))) AS municipality,
    TRIM(UPPER(COALESCE(FREGUESIA, N'Desconhecido'))) AS parish,
    NULL AS nuts3 -- A staging não tem NUTS3 direto, deixamos NULL por enquanto
FROM dbo.dsa_icnf_fire src
WHERE 
    -- Regra: Só insere se esta combinação AINDA NÃO EXISTIR na dimensão
    NOT EXISTS (
        SELECT 1 
        FROM dbo.dim_location tgt 
        WHERE tgt.district = TRIM(UPPER(COALESCE(src.DISTRITO, N'Desconhecido')))
          AND tgt.municipality = TRIM(UPPER(COALESCE(src.CONCELHO, N'Desconhecido')))
          AND tgt.parish = TRIM(UPPER(COALESCE(src.FREGUESIA, N'Desconhecido')))
    );