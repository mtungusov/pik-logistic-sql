-- последние 2 события (текущая и предыдущая зоны) для каждого трэкера
CREATE VIEW last_2_zones AS
SELECT tracker_id, event, time AS event_time,
  rule_id, rules.name AS rule_name,
  zones.id AS zone_id, zones.parent_id AS zone_parent_id, zones.label AS zone_label
FROM (
  SELECT
    tracker_id,
    event,
    time,
    rule_id,
    row_number()
    OVER ( PARTITION BY tracker_id
      ORDER BY time DESC ) AS rn
  FROM tracker_events
  WHERE event IN ('inzone', 'outzone')
) AS tracker_events2
  LEFT JOIN rules ON tracker_events2.rule_id = rules.id
  LEFT JOIN zones ON rules.zone_id = zones.id
WHERE tracker_events2.rn <= 2 AND zone_id IS NOT NULL

-- Статус трэкеров в одной таблице
CREATE VIEW trackers_info AS
SELECT trackers.id AS id, trackers.label AS label,
  trackers.group_id AS group_id, groups.title AS group_title,
  tracker_states.movement_status AS status_movement, tracker_states.connection_status AS status_connection, tracker_states.last_update AS status_last_update,
  tracker_states.gsm_updated AS status_gsm_update, tracker_states.gps_updated AS status_gps_update,
  tracker_states.gps_lat AS status_gps_lat, tracker_states.gps_lng AS status_gps_lng,
  tracker_events2.time AS event_time, tracker_events2.event,
  tracker_events2.zone_id AS zone_id,
  tracker_events2.zone_parent_id AS zone_parent_id,
  tracker_events2.zone_label AS zone_label,
  tracker_events2.zone_parent_label AS zone_parent_label,
  (CASE
    WHEN tracker_events2.event = 'inzone' THEN tracker_events2.zone_label
    WHEN tracker_events2.event = 'outzone' AND tracker_events2.zone_parent_id IS NOT NULL THEN tracker_events2.zone_parent_label
    ELSE NULL
  END ) AS zone_label_current,
  (CASE
    WHEN tracker_events2.event = 'outzone' AND tracker_events2.zone_parent_id IS NOT NULL THEN (
      SELECT TOP 1 max(time)
      FROM tracker_events
        LEFT JOIN rules ON tracker_events.rule_id = rules.id
        LEFT JOIN zones ON rules.zone_id = zones.id
      WHERE tracker_id = trackers.id AND event = 'inzone' AND zone_id = tracker_events2.zone_parent_id
      GROUP BY tracker_id, zone_id
    )
    ELSE NULL
   END) AS last_parent_inzone_time,
  (CASE
    WHEN tracker_events2.event = 'outzone' THEN tracker_events2.zone_label
    WHEN tracker_events2.event = 'inzone' AND tracker_events2.zone_parent_id IS NOT NULL THEN tracker_events2.zone_parent_label
  END ) AS zone_label_prev
FROM trackers
LEFT JOIN groups ON trackers.group_id = groups.id
LEFT JOIN tracker_states ON trackers.id = tracker_states.tracker_id
LEFT JOIN (
  SELECT te_1.tracker_id as tracker_id, te_1.event, te_1.time, te_1.rule_id AS rule_id, rules.name AS rule_name,
    rules.type AS rule_type,
    zones.id AS zone_id, zones.parent_id AS zone_parent_id,
    coalesce(zones.label, 'яУдаленная зона (' + CAST(te_1.rule_id AS VARCHAR(6)) + ')' ) AS zone_label,
    (SELECT TOP 1 z2.label FROM zones AS z2 WHERE z2.id = zones.parent_id) AS zone_parent_label
  FROM tracker_events AS te_1
  JOIN (
      SELECT
        tracker_id,
        max(time) AS last_time
      FROM tracker_events
      WHERE event IN ('inzone', 'outzone')
      GROUP BY tracker_id
      ) AS te_2 ON te_1.tracker_id = te_2.tracker_id
                AND te_1.time = te_2.last_time
  LEFT JOIN rules ON te_1.rule_id = rules.id
  LEFT JOIN zones ON zones.id = rules.zone_id
  ) AS tracker_events2 ON tracker_events2.tracker_id = trackers.id
WHERE trackers.live = 1
-- ORDER BY (CASE
--           WHEN event = 'inzone' OR (event = 'outzone' AND zone_parent_id IS NOT NULL) THEN 1
--           WHEN event = 'outzone' AND zone_parent_id IS NULL THEN 2
--           ELSE 3
--           END ), zone_label_current, event_time DESC


CREATE VIEW inoutzone_times AS
SELECT tracker_events.id, tracker_events.tracker_id, tracker_events.event, tracker_events.time, cast(tracker_events.time AS DATE) AS event_date, cast(tracker_events.time AS TIME(0)) AS event_time, tracker_events.rule_id, zones.id AS zone_id, zones.label AS zone_label, zones.parent_id FROM tracker_events
  LEFT JOIN rules ON tracker_events.rule_id = rules.id
  LEFT JOIN zones ON rules.zone_id = zones.id
WHERE event IN ('inzone', 'outzone')
GO

CREATE VIEW statistic_inzone_duration AS
  SELECT st_timeinzone.tracker_id, zones.label AS zone_label, groups.title AS group_title,
  datediff( SECOND, st_timeinzone.in_time, st_timeinzone.out_time) AS duration,
  cast(st_timeinzone.in_time AS DATE ) AS in_date
  FROM st_timeinzone
  LEFT JOIN trackers ON st_timeinzone.tracker_id = trackers.id
  LEFT JOIN groups ON trackers.group_id = groups.id
  LEFT JOIN zones ON st_timeinzone.zone_id = zones.id
  WHERE st_timeinzone.in_time IS NOT NULL AND st_timeinzone.out_time IS NOT NULL
GO

-- Статус трэкеров в одной таблице из ETL
CREATE VIEW trackers_info_by_etl AS
SELECT trackers.id AS tracker_id, trackers.label AS tracker_label, groups.title AS group_title,
  st_trackers_info.event, st_trackers_info.zone_id_in, zones.label AS zone_label_in, st_trackers_info.time_in,
  st_trackers_info.zone_id_out, zones2.label AS zone_label_out,st_trackers_info.time_out,
  tracker_states.movement_status, tracker_states.connection_status, tracker_states.gps_updated
FROM trackers
LEFT JOIN groups ON groups.id = trackers.group_id
LEFT JOIN st_trackers_info ON st_trackers_info.tracker_id = trackers.id
LEFT JOIN zones ON zones.id = st_trackers_info.zone_id_in
LEFT JOIN (
  SELECT id, label FROM zones
) AS zones2 ON zones2.id = st_trackers_info.zone_id_out
LEFT JOIN tracker_states ON tracker_states.tracker_id = trackers.id
WHERE trackers.live = 1
