/* Script: populate_dim_hour.sql
   Executar em: [DW.TAAD]
   Objetivo: Preencher as 24 horas do dia + hora desconhecida.
*/

-- Inserir hora "Desconhecida" na DW
IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_hour] WHERE hour_id = -1)
BEGIN
    INSERT INTO [DW.TAAD].[dbo].[dim_hour] (hour_id, hour, time_of_day)
    VALUES (-1, NULL, N'Desconhecido');
END

DECLARE @h INT = 0;
DECLARE @time_of_day NVARCHAR(50);

WHILE @h < 24
BEGIN
    -- Verifica se existe na DW
    IF NOT EXISTS (SELECT 1 FROM [DW.TAAD].[dbo].[dim_hour] WHERE hour_id = @h)
    BEGIN
        SET @time_of_day = CASE 
            WHEN @h BETWEEN 6 AND 11 THEN N'Manhã'
            WHEN @h BETWEEN 12 AND 19 THEN N'Tarde'
            WHEN @h BETWEEN 20 AND 23 THEN N'Noite'
            ELSE N'Madrugada'
        END;

        -- Insere na DW
        INSERT INTO [DW.TAAD].[dbo].[dim_hour] (hour_id, hour, time_of_day)
        VALUES (@h, @h, @time_of_day);
    END
    SET @h = @h + 1;
END;