/*
    Script: populate_dim_landcover.sql
    Objetivo: Povoar a dimensão de ocupação do solo (Landcover) a partir da Staging.
    Origem: [DSA.TAAD].[dbo].[dsa_vegetation]
    Destino: [DW.TAAD].[dbo].[dim_landcover]
*/

-- 1. Inserir 'Desconhecido' (-1) na DW se não existir
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_landcover] WHERE landcover_id = -1)
BEGIN
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_landcover] ON;
    INSERT INTO [DW.TAAD].[dbo].[dim_landcover] (
        landcover_id, 
        corine_code, 
        corine_description, 
        fuel_category, 
        typical_fuel_load, 
        dominant_species_hint
    )
    VALUES (
        -1, 
        NULL, 
        N'Desconhecido', 
        N'Desconhecido', 
        NULL, 
        NULL
    );
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_landcover] OFF;
END

-- 2. Inserir novas classificações de solo detetadas
-- Nota: Selecionamos DISTINCT para evitar duplicados.
-- Assumimos que a mesma combinação de código+descrição+combustível cria uma nova entrada de dimensão.
INSERT INTO [DW.TAAD].[dbo].[dim_landcover] (
    corine_code, 
    corine_description, 
    fuel_category,
    typical_fuel_load,
    dominant_species_hint
)
SELECT DISTINCT
    TRY_CAST(corine_code AS INT) AS corine_code,
    TRIM(COALESCE(corine_description, N'Desconhecido')) AS corine_description,
    TRIM(COALESCE(fuel_category, N'Desconhecido')) AS fuel_category,
    NULL AS typical_fuel_load,    -- Valor não disponível na staging
    NULL AS dominant_species_hint -- Valor não disponível ou requer agregação complexa
FROM [DSA.TAAD].[dbo].[dsa_vegetation] src
WHERE TRY_CAST(corine_code AS INT) IS NOT NULL -- Ignorar códigos inválidos
  AND NOT EXISTS (
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_landcover] tgt
    WHERE tgt.corine_code = TRY_CAST(src.corine_code AS INT)
      AND tgt.corine_description = TRIM(COALESCE(src.corine_description, N'Desconhecido'))
      AND tgt.fuel_category = TRIM(COALESCE(src.fuel_category, N'Desconhecido'))
);