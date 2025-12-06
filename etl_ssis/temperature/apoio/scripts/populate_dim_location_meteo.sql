/*
    Script: populate_dim_location_meteo.sql
    Objetivo: Garantir que as localizações dos registos de meteorologia existem na dimensão.
    Estratégia: Faz JOIN com a dsa_icnf_fire para obter Distrito/Concelho.
*/

-- Inserir combinações únicas baseadas nos incidentes presentes na meteorologia
INSERT INTO dbo.dim_location (district, municipality, parish, nuts3)
SELECT DISTINCT
    TRIM(UPPER(COALESCE(f.DISTRITO, N'Desconhecido'))) AS district,
    TRIM(UPPER(COALESCE(f.CONCELHO, N'Desconhecido'))) AS municipality,
    TRIM(UPPER(COALESCE(f.FREGUESIA, N'Desconhecido'))) AS parish,
    NULL AS nuts3
FROM dbo.dsa_meteorology m
-- JOIN com a staging de incêndios para recuperar os nomes da localização
INNER JOIN dbo.dsa_icnf_fire f ON m.incident_id = f.id
WHERE 
    -- Só insere se esta combinação AINDA NÃO EXISTIR na dimensão
    NOT EXISTS (
        SELECT 1 
        FROM dbo.dim_location tgt 
        WHERE tgt.district = TRIM(UPPER(COALESCE(f.DISTRITO, N'Desconhecido')))
          AND tgt.municipality = TRIM(UPPER(COALESCE(f.CONCELHO, N'Desconhecido')))
          AND tgt.parish = TRIM(UPPER(COALESCE(f.FREGUESIA, N'Desconhecido')))
    );