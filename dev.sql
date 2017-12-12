CREATE DATABASE [pik-logistic-dev];
GO

USE [pik-logistic-dev];
GO

CREATE TABLE trackers (
  id INT NOT NULL PRIMARY KEY,
  label NVARCHAR(250) NOT NULL,
  group_id INT,
  live BIT NOT NULL DEFAULT 0
);
-- ALTER TABLE trackers
--     ADD live BIT NOT NULL DEFAULT 0;

CREATE TABLE groups (
  id INT NOT NULL PRIMARY KEY,
  title NVARCHAR(250) NOT NULL,
  live BIT NOT NULL DEFAULT 0
);


CREATE TABLE rules (
  id INT NOT NULL PRIMARY KEY,
  type VARCHAR(250) NOT NULL,
  name NVARCHAR(500) NOT NULL,
  zone_id INT
);

CREATE TABLE zones (
  id INT NOT NULL PRIMARY KEY,
  label NVARCHAR(500) NOT NULL,
  address NVARCHAR(1000) NULL,
  parent_id INT NULL,
  live BIT NOT NULL DEFAULT 0
);


-- ALTER TABLE zones ADD address NVARCHAR(1000) NULL;
-- GO

CREATE TABLE tracker_events (
  id INT NOT NULL PRIMARY KEY,
  event VARCHAR(250) NOT NULL,
  time DATETIME2(0) NOT NULL,
  tracker_id INT NOT NULL,
  rule_id INT NULL,
  message NVARCHAR(500),
  address NVARCHAR(1000)
);
GO

CREATE INDEX idx_tracker_events_tracker_id ON tracker_events(tracker_id);
CREATE INDEX idx_tracker_events_time ON tracker_events(time);
GO


-- CREATE TABLE tracker_states (
--   tracker_id INT NOT NULL PRIMARY KEY,
--   last_update DATETIME2(0),
--   movement_status VARCHAR(250) NOT NULL,
--   connection_status VARCHAR(250) NOT NULL
-- );

-- DROP TABLE tracker_states;
CREATE TABLE tracker_states (
  tracker_id INT NOT NULL PRIMARY KEY,
  last_update DATETIME2(0),
  movement_status VARCHAR(250) NOT NULL,
  connection_status VARCHAR(250) NOT NULL,
  gsm_updated DATETIME2(0),
  gps_updated DATETIME2(0),
  gps_lat NUMERIC(9,6),
  gps_lng NUMERIC(9,6)
);
GO

CREATE INDEX idx_tracker_states_last_update ON tracker_states(last_update);
GO

-- статистика по времени в гео-зоне
CREATE TABLE st_timeinzone
(
  guid UNIQUEIDENTIFIER PRIMARY KEY NOT NULL DEFAULT NEWSEQUENTIALID(),
  tracker_id INT NOT NULL,
  zone_id INT NOT NULL,
  in_time DATETIME2(0),
  out_time DATETIME2(0)
);
GO

CREATE INDEX idx_st_timeinzone_tracker_id
  ON st_timeinzone(tracker_id);

CREATE INDEX idx_st_timeinzone_zone_id
  ON st_timeinzone(zone_id);

CREATE INDEX idx_st_timeinzone_in_time
  ON st_timeinzone(in_time);

CREATE INDEX idx_st_timeinzone_out_time
  ON st_timeinzone(out_time);
GO

CREATE TABLE etl_state_timeinzone
(
  state_name VARCHAR(32) NOT NULL PRIMARY KEY,
  state_value VARCHAR(250) NOT NULL
);
GO

-- статусы процессов ETL
CREATE TABLE etl_state
(
  etl_name VARCHAR(32) NOT NULL,
  state_name VARCHAR(32) NOT NULL,
  state_value VARCHAR(250) NOT NULL,
  CONSTRAINT PK_etl_state PRIMARY KEY (etl_name, state_name)
)

CREATE TABLE st_trackers_info
(
  tracker_id INT NOT NULL PRIMARY KEY,

  event_id INT NOT NULL,
  event VARCHAR(250) NOT NULL,

  zone_id_in INT,
  time_in DATETIME2(0),

  zone_id_out INT,
  time_out DATETIME2(0)
)

-- CHANGES!!!
-- 2017-11-22 for loader
-- ALTER TABLE zones ADD live BIT NOT NULL DEFAULT 0;
-- ALTER TABLE groups ADD live BIT NOT NULL DEFAULT 0;
