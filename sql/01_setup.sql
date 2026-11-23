-- The Deportation Math: setup (PostgreSQL)
-- Data: ICE FOIA data via the Deportation Data Project (UC Berkeley)
--   arrests  : Oct 2022 - Aug 2026 (latest release)
--   removals : Sep 2023 - Jul 2025 (late July 2025 release, the project's most reliable removals file)
-- CSVs made by scripts/xlsx_to_csv.py (Excel dates already converted)

-- 0. Tables -------------------------------------------------------------
CREATE TABLE arrests (
    aor                          TEXT,
    county                       TEXT,
    apprehension_criminality     TEXT,       -- 1 Convicted / 2 Pending charges / 3 Other immigration violator
    apprehension_date            TIMESTAMP,
    event_landmark               TEXT,
    apprehension_method          TEXT,
    state                        TEXT,
    city                         TEXT,
    birth_year                   TEXT,
    case_category                TEXT,
    case_status                  TEXT,
    case_threat_level            TEXT,
    citizenship_country          TEXT,
    departed_date                DATE,       -- blank = no departure recorded (yet)
    departure_country            TEXT,
    final_order_date             DATE,
    final_order_yes_no           TEXT,
    final_program                TEXT,
    final_program_group          TEXT,
    gender                       TEXT,
    alien_file_number            TEXT,       -- don't publish
    anonymized_unique_identifier TEXT,       -- one person can have several arrests
    source_file_fy               TEXT
);

CREATE TABLE removals (
    departed_date                      DATE,
    port_of_departure                  TEXT,
    departure_country                  TEXT,
    docket_aor                         TEXT,
    apprehension_state                 TEXT,
    apprehension_county                TEXT,
    case_status                        TEXT,
    gender                             TEXT,
    birth_country                      TEXT,
    citizenship_country                TEXT,
    birth_date                         TEXT,
    birth_year                         TEXT,
    entry_date                         DATE,
    entry_status                       TEXT,
    msc_ncic_charge                    TEXT,     -- most serious criminal charge
    msc_ncic_charge_code               TEXT,
    msc_charge_date                    DATE,
    msc_criminal_charge_status         TEXT,
    msc_criminal_charge_status_code    TEXT,
    msc_conviction_date                DATE,
    case_threat_level                  TEXT,
    case_criminality                   TEXT,     -- 1 Convicted / 2 Pending charges / 3 Other immigration violator
    felon                              TEXT,
    processing_disposition             TEXT,
    case_category                      TEXT,
    final_program                      TEXT,
    final_program_code                 TEXT,
    case_category_time_of_arrest       TEXT,
    latest_arrest_program_current      TEXT,
    latest_arrest_program_current_code TEXT,
    latest_person_apprehension_date    TEXT,     -- still an Excel serial number, convert if needed
    final_order_yes_no                 TEXT,
    final_order_date                   DATE,
    final_charge_code                  TEXT,
    final_charge_section_code          TEXT,
    prior_deport_yes_no                TEXT,
    latest_person_departed_date        DATE,
    alien_file_number                  TEXT,     -- don't publish
    eid_case_id                        TEXT,
    eid_subject_id                     TEXT,
    unique_identifier                  TEXT
);

-- Load with pgAdmin: right-click table > Import/Export > Import, Format csv, Header ON
--   arrests  <- /Users/manny/Documents/deportation-data/data/clean/arrests_all.csv
--   removals <- /Users/manny/Documents/deportation-data/data/clean/removals_jul2025.csv

-- 1. Sanity checks ------------------------------------------------------
-- Expect 896,393 rows, 812,824 people, 2022-10-01 to 2026-08-06
SELECT COUNT(*), COUNT(DISTINCT anonymized_unique_identifier),
       MIN(apprehension_date)::date, MAX(apprehension_date)::date
FROM arrests;

-- Expect 528,441 rows, 2023-09-01 to 2025-07-28
SELECT COUNT(*), MIN(departed_date), MAX(departed_date) FROM removals;

-- Expect 3 values: Convicted 309,919 / Pending 221,381 / Other 365,093
SELECT apprehension_criminality, COUNT(*) FROM arrests GROUP BY 1 ORDER BY 1;

ALTER TABLE removals
  ALTER COLUMN entry_date                  TYPE TEXT,
  ALTER COLUMN msc_charge_date             TYPE TEXT,
  ALTER COLUMN msc_conviction_date         TYPE TEXT,
  ALTER COLUMN final_order_date            TYPE TEXT,
  ALTER COLUMN latest_person_departed_date TYPE TEXT;
