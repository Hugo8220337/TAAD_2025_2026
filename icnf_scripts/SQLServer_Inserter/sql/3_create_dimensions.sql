-- Creates dimension tables for ICNF fire data
-- File: 3_create_dimensions.sql
-- Location: icnf_scripts/SQLServer_Inserter/sql

IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.dim_hour') AND type = N'U'
)
BEGIN
CREATE TABLE dbo.dim_hour (
    hour_id INT NOT NULL,
    hour TINYINT NULL,
    time_of_day NVARCHAR(50) NULL,
    CONSTRAINT PK_dim_hour PRIMARY KEY CLUSTERED (hour_id)
);
END

IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.dim_day') AND type = N'U'
)
BEGIN
CREATE TABLE dbo.dim_day (
    day_id INT NOT NULL,
    day TINYINT NULL,
    month TINYINT NULL,
    year SMALLINT NULL,
    week TINYINT NULL,
    season NVARCHAR(20) NULL,
    weekday NVARCHAR(20) NULL,
    CONSTRAINT PK_dim_day PRIMARY KEY CLUSTERED (day_id)
);
END

IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.dim_location') AND type = N'U'
)
BEGIN
CREATE TABLE dbo.dim_location (
    location_id INT IDENTITY(1,1) NOT NULL,
    district NVARCHAR(200) NULL,
    municipality NVARCHAR(200) NULL,
    parish NVARCHAR(200) NULL,
    nuts3 NVARCHAR(50) NULL,
    CONSTRAINT PK_dim_location PRIMARY KEY CLUSTERED (location_id)
);
END

IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.dim_fire_type') AND type = N'U'
)
BEGIN
CREATE TABLE dbo.dim_fire_type (
    fire_type_id INT IDENTITY(1,1) NOT NULL,
    type_name NVARCHAR(200) NULL,
    is_control_burn BIT NULL,
    is_false_alarm BIT NULL,
    is_agricultural BIT NULL,
    CONSTRAINT PK_dim_fire_type PRIMARY KEY CLUSTERED (fire_type_id)
);
END

IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.dim_cause') AND type = N'U'
)
BEGIN
CREATE TABLE dbo.dim_cause (
    cause_id INT IDENTITY(1,1) NOT NULL,
    cause_name NVARCHAR(200) NULL,
    cause_category NVARCHAR(100) NULL,
    cause_family NVARCHAR(100) NULL,
    CONSTRAINT PK_dim_cause PRIMARY KEY CLUSTERED (cause_id)
);
END