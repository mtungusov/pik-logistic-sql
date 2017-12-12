CREATE VIEW statistic_aggregate_inzone_duration_days AS
SELECT in_date, zone_label, group_title, tracker_id, sum(duration) AS total_duration_in_sec
FROM statistic_inzone_duration
GROUP BY in_date, zone_label, group_title, tracker_id

-- Простой по геозонам
SELECT zone_label, count(duration) AS inzone_count, (avg(duration) / 60) AS avg_time_in_minutes
FROM statistic_inzone_duration
WHERE in_date BETWEEN '2017-10-01' AND '2017-11-01'
  AND zone_label IN ('480 КЖИ - погр.', 'ДСК-Град - погр.')
  AND group_title IN ('Водовоз', '-Инлоудер')
  AND duration < (60 * 60 * 8)
GROUP BY zone_label
ORDER BY zone_label

-- Простой по группам транспорта
SELECT group_title, count(duration) AS inzone_count, (avg(duration) / 60) AS avg_time_in_minutes
FROM statistic_inzone_duration
WHERE in_date BETWEEN '2017-10-01' AND '2017-11-01'
  AND zone_label IN ('480 КЖИ - погр.', 'ДСК-Град - погр.')
  AND group_title IN ('Борт 12т.-20т.', '-Инлоудер')
  AND duration < (60 * 60 * 8)
GROUP BY group_title
ORDER BY group_title

-- Простой по геозонам и группам транспорта
SELECT zone_label, group_title, count(duration) AS inzone_count, (avg(duration) / 60) AS avg_time_in_minutes
FROM statistic_inzone_duration
WHERE in_date BETWEEN '2017-10-01' AND '2017-11-01'
  AND zone_label IN ('480 КЖИ - погр.', 'ДСК-Град - погр.')
  AND group_title IN ('Борт 12т.-20т.', '-Инлоудер')
  AND duration < (60 * 60 * 8)
GROUP BY zone_label, group_title
ORDER BY zone_label, group_title
