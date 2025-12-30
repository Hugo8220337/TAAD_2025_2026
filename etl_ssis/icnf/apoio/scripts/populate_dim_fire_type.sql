/*
    Script: populate_dim_fire_type.sql
    Objetivo: Povoar a dimensão de tipos de incêndio e flags booleanas.
*/

IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_fire_type] WHERE fire_type_id = -1)
BEGIN
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_fire_type] ON;
    INSERT INTO [DW.TAAD].[dbo].[dim_fire_type] (fire_type_id, type_name, is_control_burn, is_false_alarm, is_agricultural)
    VALUES (-1, N'Desconhecido', 0, 0, 0);
    SET IDENTITY_INSERT [DW.TAAD].[dbo].[dim_fire_type] OFF;
END

INSERT INTO [DW.TAAD].[dbo].[dim_fire_type] (type_name, is_control_burn, is_false_alarm, is_agricultural)
SELECT DISTINCT
    TRIM(UPPER(COALESCE(TIPO, N'Desconhecido'))),
    CASE WHEN TRIM(QUEIMADA) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END,
    CASE WHEN TRIM(FALSOALARME) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END,
    CASE WHEN TRIM(AGRICOLA) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END
FROM [dbo].[dsa_icnf_fire] src
WHERE NOT EXISTS (
    SELECT 1 FROM [DW.TAAD].[dbo].[dim_fire_type] tgt 
    WHERE tgt.type_name = TRIM(UPPER(COALESCE(src.TIPO, N'Desconhecido')))
      AND tgt.is_control_burn = CASE WHEN TRIM(src.QUEIMADA) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END
);