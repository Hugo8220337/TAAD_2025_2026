/*
    Script: populate_dim_fire_type.sql
    Objetivo: Povoar a dimensão de tipos de incêndio e flags booleanas.
*/

-- 1. Inserir registo "Desconhecido" (ID -1) se não existir
IF NOT EXISTS (SELECT 1 FROM dbo.dim_fire_type WHERE fire_type_id = -1)
BEGIN
    SET IDENTITY_INSERT dbo.dim_fire_type ON;
    
    INSERT INTO dbo.dim_fire_type (fire_type_id, type_name, is_control_burn, is_false_alarm, is_agricultural)
    VALUES (-1, N'Desconhecido', 0, 0, 0);
    
    SET IDENTITY_INSERT dbo.dim_fire_type OFF;
END

-- 2. Inserir combinações únicas da Staging Area
INSERT INTO dbo.dim_fire_type (type_name, is_control_burn, is_false_alarm, is_agricultural)
SELECT DISTINCT
    TRIM(UPPER(COALESCE(TIPO, N'Desconhecido'))) AS type_name,
    
    -- Conversão robusta de Texto para BIT (Aceita '1', 'Sim', 'S', 'True')
    CASE 
        WHEN TRIM(QUEIMADA) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 
        ELSE 0 
    END AS is_control_burn,

    CASE 
        WHEN TRIM(FALSOALARME) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 
        ELSE 0 
    END AS is_false_alarm,

    CASE 
        WHEN TRIM(AGRICOLA) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 
        ELSE 0 
    END AS is_agricultural

FROM dbo.dsa_icnf_fire src
WHERE 
    -- Só insere se esta combinação exata AINDA NÃO EXISTIR
    NOT EXISTS (
        SELECT 1 
        FROM dbo.dim_fire_type tgt 
        WHERE tgt.type_name = TRIM(UPPER(COALESCE(src.TIPO, N'Desconhecido')))
          AND tgt.is_control_burn = (CASE WHEN TRIM(src.QUEIMADA) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END)
          AND tgt.is_false_alarm = (CASE WHEN TRIM(src.FALSOALARME) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END)
          AND tgt.is_agricultural = (CASE WHEN TRIM(src.AGRICOLA) IN ('1', 'Sim', 'S', 'True', 'Yes') THEN 1 ELSE 0 END)
    );