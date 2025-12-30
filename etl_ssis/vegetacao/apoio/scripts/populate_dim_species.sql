/*
    Script: populate_dim_species.sql
    Objetivo: Povoar a dimensão de espécies a partir da Staging.
    Origem: [DSA.TAAD].[dbo].[dsa_vegetation]
    Destino: [DW.TAAD].[dbo].[dim_species]
*/

-- 1. Inserir 'Desconhecido' (-1) na DW se não existir
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_species] WHERE species_id = -1)
BEGIN
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_species] ON;
    INSERT INTO [DW.TAAD].[dbo].[dim_species] (species_id, species_name, flammability_score)
    VALUES (-1, N'Desconhecido', NULL);
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_species] OFF;
END

-- 2. Inserir novas espécies detetadas
-- Nota: O flammability_score entra como NULL pois não existe na fonte de dados bruta (Staging).
INSERT INTO [DW.TAAD].[dbo].[dim_species] (species_name, flammability_score)
SELECT DISTINCT
    TRIM(UPPER(COALESCE(species_name, N'Desconhecido'))) AS species_name,
    NULL AS flammability_score
FROM [DSA.TAAD].[dbo].[dsa_vegetation] src
WHERE src.species_name IS NOT NULL -- Ignorar nulos se quisermos mapear NULL -> ID -1 na FactTable
  AND TRIM(src.species_name) <> '' -- Ignorar strings vazias
  AND NOT EXISTS (
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_species] tgt
    WHERE tgt.species_name = TRIM(UPPER(COALESCE(src.species_name, N'Desconhecido')))
);