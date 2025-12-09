/*
    Script: populate_dim_cause.sql
    Objetivo: Povoar a dimensão de causas com base nos dados únicos da staging.
*/


IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_cause] WHERE cause_id = -1)
BEGIN
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_cause] ON;
    INSERT INTO [DW.TAAD].[dbo].[dim_cause] (cause_id, cause_name, cause_category, cause_family)
    VALUES (-1, N'Desconhecido', N'Desconhecido', N'Desconhecido');
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_cause] OFF;
END

INSERT INTO [DW.TAAD].[dbo].[dim_cause] (cause_name, cause_category, cause_family)
SELECT DISTINCT
    TRIM(UPPER(COALESCE(CAUSA, N'Desconhecido'))),
    TRIM(UPPER(COALESCE(TIPOCAUSA, N'Desconhecido'))),
    TRIM(UPPER(COALESCE(CAUSAFAMILIA, N'Desconhecido')))
FROM [dbo].[dsa_icnf_fire] src
WHERE NOT EXISTS (
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_cause] tgt 
    WHERE tgt.cause_name = TRIM(UPPER(COALESCE(src.CAUSA, N'Desconhecido')))
      AND tgt.cause_category = TRIM(UPPER(COALESCE(src.TIPOCAUSA, N'Desconhecido')))
      AND tgt.cause_family = TRIM(UPPER(COALESCE(src.CAUSAFAMILIA, N'Desconhecido')))
);