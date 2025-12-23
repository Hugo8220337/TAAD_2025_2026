/*
    Script: clean_fact_vegetation.sql
    Objetivo: Apagar registos da fact_vegetation onde o location_id é -1 (Desconhecido).
*/
DELETE FROM [DW.TAAD].[dbo].[fact_vegetation]
WHERE location_id = -1;