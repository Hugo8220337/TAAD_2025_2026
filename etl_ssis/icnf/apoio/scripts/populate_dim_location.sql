/*
    Script: populate_dim_location.sql
    Objetivo: Povoar a dimensão localização com base nos dados únicos da staging.
    Nota: Usa IDENTITY_INSERT para forçar o ID -1 (Desconhecido).
*/

-- Inserir 'Desconhecido' (-1) na DW
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_location] WHERE location_id = -1)
BEGIN
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_location] ON;
    INSERT INTO [DW.TAAD].[dbo].[dim_location] (location_id, district, municipality, parish, nuts3)
    VALUES (-1, N'Desconhecido', N'Desconhecido', N'Desconhecido', NULL);
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_location] OFF;
END

INSERT INTO [DW.TAAD].[dbo].[dim_location] (district, municipality, parish, nuts3)
SELECT DISTINCT
    TRIM(UPPER(COALESCE(DISTRITO, N'Desconhecido'))),
    TRIM(UPPER(COALESCE(CONCELHO, N'Desconhecido'))),
    TRIM(UPPER(COALESCE(FREGUESIA, N'Desconhecido'))),
    NULL
FROM [dbo].[dsa_icnf_fire] src -- Local
WHERE NOT EXISTS (
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_location] tgt -- Remoto
    WHERE tgt.district = TRIM(UPPER(COALESCE(src.DISTRITO, N'Desconhecido')))
      AND tgt.municipality = TRIM(UPPER(COALESCE(src.CONCELHO, N'Desconhecido')))
      AND tgt.parish = TRIM(UPPER(COALESCE(src.FREGUESIA, N'Desconhecido')))
);