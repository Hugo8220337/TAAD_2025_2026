/*
    Script: populate_dim_cause.sql
    Objetivo: Povoar a dimensão de causas com base nos dados únicos da staging.
*/

-- 1. Inserir registo "Desconhecido" (ID -1) se não existir
IF NOT EXISTS (SELECT 1 FROM dbo.dim_cause WHERE cause_id = -1)
BEGIN
    SET IDENTITY_INSERT dbo.dim_cause ON;
    
    INSERT INTO dbo.dim_cause (cause_id, cause_name, cause_category, cause_family)
    VALUES (-1, N'Desconhecido', N'Desconhecido', N'Desconhecido');
    
    SET IDENTITY_INSERT dbo.dim_cause OFF;
END

-- 2. Inserir combinações únicas da Staging Area
--    Mapeamento:
--    CAUSA        -> cause_name
--    TIPOCAUSA    -> cause_category
--    CAUSAFAMILIA -> cause_family
INSERT INTO dbo.dim_cause (cause_name, cause_category, cause_family)
SELECT DISTINCT
    TRIM(UPPER(COALESCE(CAUSA, N'Desconhecido'))) AS cause_name,
    TRIM(UPPER(COALESCE(TIPOCAUSA, N'Desconhecido'))) AS cause_category,
    TRIM(UPPER(COALESCE(CAUSAFAMILIA, N'Desconhecido'))) AS cause_family
FROM dbo.dsa_icnf_fire src
WHERE 
    -- Só insere se esta combinação AINDA NÃO EXISTIR
    NOT EXISTS (
        SELECT 1 
        FROM dbo.dim_cause tgt 
        WHERE tgt.cause_name     = TRIM(UPPER(COALESCE(src.CAUSA, N'Desconhecido')))
          AND tgt.cause_category = TRIM(UPPER(COALESCE(src.TIPOCAUSA, N'Desconhecido')))
          AND tgt.cause_family   = TRIM(UPPER(COALESCE(src.CAUSAFAMILIA, N'Desconhecido')))
    );