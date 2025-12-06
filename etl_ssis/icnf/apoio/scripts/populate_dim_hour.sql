DECLARE @h INT = 0;
DECLARE @time_of_day NVARCHAR(50);

WHILE @h < 24
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.dim_hour WHERE hour_id = @h)
    BEGIN
        SET @time_of_day = CASE 
            WHEN @h BETWEEN 6 AND 11 THEN 'Manhã'
            WHEN @h BETWEEN 12 AND 19 THEN 'Tarde'
            WHEN @h BETWEEN 20 AND 23 THEN 'Noite'
            ELSE 'Madrugada'
        END;

        INSERT INTO dbo.dim_hour (hour_id, hour, time_of_day)
        VALUES (@h, @h, @time_of_day);
    END
    SET @h = @h + 1;
END;

IF NOT EXISTS (SELECT 1 FROM dbo.dim_hour WHERE hour_id = -1)
BEGIN
    INSERT INTO dbo.dim_hour (hour_id, hour, time_of_day)
    VALUES (-1, NULL, 'Desconhecido');
END