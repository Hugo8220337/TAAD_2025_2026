/*
    Script: filter_area_less_than_01.sql
    Objetivo: Remover registos onde a área total é inferior a 0.1 hectares.
*/

DELETE FROM dbo.dsa_icnf_fire
WHERE 
    -- Substitui a vírgula por ponto (caso venha no formato PT) e converte para número
    TRY_CAST(REPLACE(AREATOTAL, ',', '.') AS FLOAT) < 0.1;