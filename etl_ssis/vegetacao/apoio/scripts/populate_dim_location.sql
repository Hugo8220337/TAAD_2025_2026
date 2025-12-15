/*
    Script: populate_dim_location.sql
    Objetivo: Povoar a dimensão localização com base nos dados únicos da staging de vegetação.
    Origem: [DSA.TAAD].[dbo].[dsa_vegetation]
    Destino: [DW.TAAD].[dbo].[dim_location]
*/

-- 1. Garantir que o registo 'Desconhecido' (-1) existe (caso o script dos fogos ainda não tenha corrido)
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_location] WHERE location_id = -1)
BEGIN
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_location] ON;
    INSERT INTO [DW.TAAD].[dbo].[dim_location] (location_id, district, municipality, parish, nuts3)
    VALUES (-1, N'Desconhecido', N'Desconhecido', N'Desconhecido', NULL);
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_location] OFF;
END

-- 2. Inserir novas localizações detetadas na vegetação
INSERT INTO [DW.TAAD].[dbo].[dim_location] (district, municipality, parish, nuts3)
SELECT DISTINCT
    TRIM(UPPER(COALESCE(district, N'Desconhecido'))),
    TRIM(UPPER(COALESCE(municipality, N'Desconhecido'))),
    TRIM(UPPER(COALESCE(parish, N'Desconhecido'))),
    TRIM(UPPER(nuts3)) -- NUTS3 pode ser NULL ou preenchido se existir na fonte
FROM [DSA.TAAD].[dbo].[dsa_vegetation] src
WHERE NOT EXISTS (
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_location] tgt
    WHERE tgt.district = TRIM(UPPER(COALESCE(src.district, N'Desconhecido')))
      AND tgt.municipality = TRIM(UPPER(COALESCE(src.municipality, N'Desconhecido')))
      AND tgt.parish = TRIM(UPPER(COALESCE(src.parish, N'Desconhecido')))
);