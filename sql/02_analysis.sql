-- ICE arrests analysis (PostgreSQL)
-- Run sql/01_setup.sql first.
-- 'No criminal record' = apprehension_criminality '3 Other Immigration Violator'
-- 'Criminal record' = '1 Convicted Criminal' or '2 Pending Criminal Charges'

-- Query 1: arrests per day and share by criminal record, before vs after Jan 20, 2025
SELECT
apprehension_criminality,
CASE
  WHEN apprehension_date < '2025-01-20'  THEN 'Before'
  ELSE 'After'
END AS period,
count(*) as cnt_period,
ROUND( COUNT(*)::numeric / ( MAX(apprehension_date)::date - MIN(apprehension_date)::date + 1 ), 1 ) AS per_day,
ROUND( 100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY 
CASE
  WHEN apprehension_date < '2025-01-20'  THEN 'Before'
  ELSE 'After'
END), 1 ) AS pct
FROM arrests
group by apprehension_criminality , period
ORDER BY apprehension_criminality, period;

-- Query 2: share with a departure recorded within 90 days of arrest
--   only arrests before 2026-05-09, so every arrest gets a full 90-day window

SELECT
apprehension_criminality,
CASE
  WHEN apprehension_date < '2025-01-20'  THEN 'Before'
  ELSE 'After'
END AS period,
count(*) as cnt_period,
SUM(
CASE WHEN departed_date BETWEEN apprehension_date::date
                                AND apprehension_date::date + 90
          THEN 1 ELSE 0 END ) AS removed_90,
ROUND(100.0 * SUM(CASE WHEN departed_date BETWEEN apprehension_date::date
                                AND apprehension_date::date + 90
          THEN 1 ELSE 0 END) / count(*), 1) as pct_removed_90
FROM arrests
WHERE apprehension_date < '2026-05-09' 
GROUP BY apprehension_criminality , period
ORDER BY apprehension_criminality, period;

-- Query 3: monthly 90-day departure rate, no-record group
--   check: does the jump happen at Jan 20, 2025 or at a fiscal-year file boundary?

SELECT
apprehension_criminality,
CASE
  WHEN apprehension_date < '2025-01-20'  THEN 'Before'
  ELSE 'After'
END AS period,
count(*) as cnt_period,
SUM(
CASE WHEN departed_date BETWEEN apprehension_date::date
                                AND apprehension_date::date + 90
          THEN 1 ELSE 0 END ) AS removed_90,
ROUND(100.0 * SUM(CASE WHEN departed_date BETWEEN apprehension_date::date
                                AND apprehension_date::date + 90
          THEN 1 ELSE 0 END) / count(*), 1) as pct_removed_90,
DATE_TRUNC('month', apprehension_date)::date AS month
FROM arrests
WHERE apprehension_date < '2026-05-09' AND apprehension_criminality = '3 Other Immigration Violator'
GROUP BY apprehension_criminality , period , month
ORDER BY month;


-- Query 4: yearly 90-day departure rate, no-record group

SELECT 
apprehension_criminality,
CASE
  WHEN apprehension_date < '2025-01-20'  THEN 'Before'
  ELSE 'After'
END AS period,
count(*) as cnt_period,
SUM(
CASE WHEN departed_date BETWEEN apprehension_date::date
                                AND apprehension_date::date + 90
          THEN 1 ELSE 0 END ) AS removed_90,
ROUND(100.0 * SUM(CASE WHEN departed_date BETWEEN apprehension_date::date
                                AND apprehension_date::date + 90
          THEN 1 ELSE 0 END) / count(*), 1) as pct_removed_90,
DATE_TRUNC('year', apprehension_date) :: date as year
FROM arrests
WHERE apprehension_date < '2026-05-09' AND apprehension_criminality = '3 Other Immigration Violator'
GROUP BY apprehension_criminality , period , year
ORDER BY year;

-- Query 5: how no-record arrests were made (apprehension method), before vs after

SELECT
apprehension_method,
count(*) as cnt_period,
CASE
  WHEN apprehension_date < '2025-01-20'  THEN 'Before'
  ELSE 'After'
END AS period
FROM arrests 
WHERE apprehension_criminality = '3 Other Immigration Violator'
GROUP BY apprehension_method, period
order by period, cnt_period DESC;

-- Query 6: arrests per day and share of arrests by year and criminal record

SELECT
apprehension_criminality,
EXTRACT(YEAR FROM apprehension_date) as year,
count(*) as cnt_period,
ROUND( COUNT(*)::numeric / ( MAX(apprehension_date)::date - MIN(apprehension_date)::date + 1 ), 1 ) AS per_day,
ROUND( 100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY 
EXTRACT(YEAR FROM apprehension_date)), 1 ) AS pct
FROM arrests
group by EXTRACT(YEAR FROM apprehension_date) , apprehension_criminality 
ORDER BY year, apprehension_criminality;


-- Query 7: monthly summary exported for Tableau (data/output/tableau_monthly.csv)

SELECT 
DATE_TRUNC('month', apprehension_date):: date AS month,
apprehension_criminality,
count(*) as arrest_cnt,
CASE
  WHEN apprehension_date < '2025-01-20'  THEN 'Before'
  ELSE 'After'
END AS period,
SUM(CASE WHEN
	apprehension_date < '2026-05-09' THEN 1
	ELSE 0 END) AS eligible_90,
SUM(CASE WHEN
	apprehension_date < '2026-05-09' AND departed_date BETWEEN apprehension_date::date
                                AND apprehension_date::date + 90
          THEN 1 ELSE 0 END) AS removed_90 
FROM arrests
GROUP BY month, apprehension_criminality, period
ORDER BY month, apprehension_criminality;
