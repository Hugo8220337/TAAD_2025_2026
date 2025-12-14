/*
    Script: populate_dim_cause.sql
    Objetivo: Povoar a dimensão de causas com base nos dados únicos da staging.
*/


-- Garante que o ID -1 (Desconhecido) existe
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_cause] WHERE cause_id = -1)
BEGIN
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_cause] ON;
    INSERT INTO [DW.TAAD].[dbo].[dim_cause] (cause_id, cause_name, cause_category, cause_family)
    VALUES (-1, N'DESCONHECIDO', N'DESCONHECIDO', N'DESCONHECIDO');
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_cause] OFF;
END

-- Insere novos registos tratando VAZIOS como NULL -> DESCONHECIDO
INSERT INTO [DW.TAAD].[dbo].[dim_cause] (cause_name, cause_category, cause_family)
SELECT DISTINCT
    TRIM(UPPER(COALESCE(NULLIF(TRIM(CAUSA), ''), N'DESCONHECIDO'))),
    TRIM(UPPER(COALESCE(NULLIF(TRIM(TIPOCAUSA), ''), N'DESCONHECIDO'))),
    TRIM(UPPER(COALESCE(NULLIF(TRIM(CAUSAFAMILIA), ''), N'DESCONHECIDO')))
FROM [dbo].[dsa_icnf_fire] src
WHERE NOT EXISTS (
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_cause] tgt 
    WHERE tgt.cause_name     = TRIM(UPPER(COALESCE(NULLIF(TRIM(src.CAUSA), ''), N'DESCONHECIDO')))
      AND tgt.cause_category = TRIM(UPPER(COALESCE(NULLIF(TRIM(src.TIPOCAUSA), ''), N'DESCONHECIDO')))
      AND tgt.cause_family   = TRIM(UPPER(COALESCE(NULLIF(TRIM(src.CAUSAFAMILIA), ''), N'DESCONHECIDO')))
);