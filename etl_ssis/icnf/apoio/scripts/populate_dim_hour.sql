/*
    Script: populate_dim_hour_bulletproof.sql
    Objetivo: Popular a dimensão de horas.
*/

-- 1. Garante que o registo -1 (Desconhecido) existe e está correto
IF EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_hour] WHERE hour_id = -1)
BEGIN
    UPDATE [DW.TAAD].[dbo].[dim_hour]
    SET [hour] = -1, 
        time_of_day = N'Desconhecido'
    WHERE hour_id = -1;
END
ELSE
BEGIN
    INSERT INTO [DW.TAAD].[dbo].[dim_hour] (hour_id, [hour], time_of_day)
    VALUES (-1, -1, N'Desconhecido');
END

-- 2. Loop para tratar as horas de 0 a 23
DECLARE @h INT = 0;

WHILE @h <= 23
BEGIN
    -- Define o texto da parte do dia
    -- NCHAR(227) é o código unicode para 'ã'. 
    -- Isto evita que o editor do SSIS ou o ficheiro de texto estraguem o caracter.
    DECLARE @PartDia NVARCHAR(50);
    SET @PartDia = CASE 
        WHEN @h BETWEEN 0 AND 5 THEN N'Madrugada'
        WHEN @h BETWEEN 6 AND 11 THEN N'Manh' + NCHAR(227) -- Constrói "Manhã" via código
        WHEN @h BETWEEN 12 AND 18 THEN N'Tarde'
        ELSE N'Noite'
    END;

    -- Lógica de UPSERT (Update se existir, Insert se não existir)
    IF EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_hour] WHERE hour_id = @h)
    BEGIN
        -- Se a hora já existe, FORÇAMOS a atualização do texto para corrigir o erro anterior
        UPDATE [DW.TAAD].[dbo].[dim_hour]
        SET time_of_day = @PartDia
        WHERE hour_id = @h;
    END
    ELSE
    BEGIN
        -- Se a hora não existe, inserimos
        INSERT INTO [DW.TAAD].[dbo].[dim_hour] (hour_id, [hour], time_of_day)
        VALUES (@h, @h, @PartDia);
    END
    
    SET @h = @h + 1;
END