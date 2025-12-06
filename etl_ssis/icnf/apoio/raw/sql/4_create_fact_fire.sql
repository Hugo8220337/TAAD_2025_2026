IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.fact_fire') AND type = N'U'
)
BEGIN
CREATE TABLE dbo.fact_fire (
    fire_id NVARCHAR(100) NOT NULL,

    alert_hour_id INT NULL,
    extinguish_hour_id INT NULL,
    first_intervention_hour_id INT NULL,

    start_day_id INT NULL,
    end_day_id INT NULL,

    location_id INT NULL,
    fire_type_id INT NULL,
    cause_id INT NULL,

    area_total_m2 FLOAT NULL,
    area_pov_m2 FLOAT NULL,
    area_shrub_m2 FLOAT NULL,
    area_agri_m2 FLOAT NULL,
    duration_hours FLOAT NULL,
    perimeter_m FLOAT NULL,

    latitude FLOAT NULL,
    longitude FLOAT NULL,
    centroid_lon FLOAT NULL,
    centroid_lat FLOAT NULL,

    ndays INT NULL,
    dry_day_sum INT NULL,
    high_wind_sum INT NULL,

    processing_date DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_fact_fire PRIMARY KEY CLUSTERED (fire_id)
);

-- Foreign keys (add after table creation to avoid dependency ordering issues)
ALTER TABLE dbo.fact_fire
    ADD CONSTRAINT FK_fact_fire_alert_hour FOREIGN KEY (alert_hour_id) REFERENCES dbo.dim_hour(hour_id);

ALTER TABLE dbo.fact_fire
    ADD CONSTRAINT FK_fact_fire_extinguish_hour FOREIGN KEY (extinguish_hour_id) REFERENCES dbo.dim_hour(hour_id);

ALTER TABLE dbo.fact_fire
    ADD CONSTRAINT FK_fact_fire_first_interv_hour FOREIGN KEY (first_intervention_hour_id) REFERENCES dbo.dim_hour(hour_id);

ALTER TABLE dbo.fact_fire
    ADD CONSTRAINT FK_fact_fire_start_day FOREIGN KEY (start_day_id) REFERENCES dbo.dim_day(day_id);

ALTER TABLE dbo.fact_fire
    ADD CONSTRAINT FK_fact_fire_end_day FOREIGN KEY (end_day_id) REFERENCES dbo.dim_day(day_id);

ALTER TABLE dbo.fact_fire
    ADD CONSTRAINT FK_fact_fire_location FOREIGN KEY (location_id) REFERENCES dbo.dim_location(location_id);

ALTER TABLE dbo.fact_fire
    ADD CONSTRAINT FK_fact_fire_fire_type FOREIGN KEY (fire_type_id) REFERENCES dbo.dim_fire_type(fire_type_id);

ALTER TABLE dbo.fact_fire
    ADD CONSTRAINT FK_fact_fire_cause FOREIGN KEY (cause_id) REFERENCES dbo.dim_cause(cause_id);

END
