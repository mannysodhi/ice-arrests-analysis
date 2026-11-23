# ICE Arrests: Who Would "Easing Up" Actually Affect?

In November 2026, President Trump told 60 Minutes his deportation push "might be too tough." I wanted to know who an easing up would actually affect, so I analyzed every ICE arrest record from October 2022 to August 2026, with a focus on people with no criminal record.

**Live dashboard (Tableau Public):** [ICE Arrests: Biden's Last 2 Years vs. Trump's First](https://public.tableau.com/app/profile/manmeet.sodhi/viz/ICEArrestsBidensLast2Yearsvs_TrumpsFirst/Dashboard1)

## Key findings

People with no criminal record (no conviction and no pending charges):

| Year | Arrests per day | Share of all ICE arrests | Departure recorded within 90 days |
|---|---|---|---|
| 2022 (Oct to Dec) | 353 | 67% | 2% |
| 2023 | 216 | 52% | 4% |
| 2024 | 69 | 23% | 19% |
| 2025 | 313 | 36% | 64% |
| 2026 (Jan to Aug) | 524 | 43% | 62% |

- All ICE arrests went from about 300 a day in 2024 to about 880 a day in 2025.
- In 2022, most arrests were of people with no criminal record, but almost none of them had a departure within 90 days. In 2025, nearly two thirds did. The biggest change is not only who gets arrested, but what happens after.
- The monthly data shows the 90-day departure rate for this group jumping right at January 20, 2025 (about 32% for January 1 to 19, about 52% for January 20 to 31), not at a fiscal-year file boundary.

## Data

- **Source:** ICE arrest records obtained through FOIA and published by the [Deportation Data Project](https://deportationdata.org/data/ice.html) (UC Berkeley).
- **Arrests:** 896,393 records, October 1, 2022 to August 6, 2026.
- **Removals:** July 2025 release (the project's most reliable removals file).
- Raw and cleaned data files are not in this repo because of their size. Download them from the source above.

## Method

1. **Clean** (`scripts/xlsx_to_csv.py`): converted ICE's Excel files to CSV, skipped title rows above the headers, turned Excel serial dates (for example 45677) into real dates, standardized column names, and combined four fiscal-year files by column name (FY2024 was missing a column).
2. **Load** (`sql/01_setup.sql`): created PostgreSQL tables and ran sanity checks against expected row counts and date ranges.
3. **Analyze** (`sql/02_analysis.sql`): 7 queries using CASE, GROUP BY, window functions (`SUM() OVER (PARTITION BY ...)`), date math and filtered aggregates.
4. **Visualize:** exported a monthly summary (`data/output/tableau_monthly.csv`) and built the dashboard in Tableau Public.

## Decisions and limitations

- **Fair time windows:** recent arrests have had less time to end in a departure, so the 90-day rate only counts arrests through May 8, 2026, which gives every arrest a full 90 days.
- **Per day, not totals:** the before and after periods have different lengths, so I compared rates per day.
- **Missing IDs:** about 2% of arrest records (19,719) have no person ID, so person-level counts leave them out.
- **Blank departure date** means no departure was recorded. It does not say why.
- **A misleading first number:** my first comparison (about 6% before vs 60% after) averaged very different years together. Breaking it out by year and month gave a fairer picture.
- **Context, not proven by this data:** Biden-era enforcement priorities included recent border crossers regardless of criminal record, which may explain some of the high no-record share in 2022 to 2023.
- **Import issue:** a few removal dates were stored in a short format like "25-05-24", which broke the load. Those extra date columns are stored as text since the analysis does not use them.

## Repo structure

```
scripts/xlsx_to_csv.py      Excel to clean CSV
sql/01_setup.sql            tables, load notes, sanity checks
sql/02_analysis.sql         analysis queries 1 to 7
data/output/                aggregated output used by the dashboard
```

**Tools:** PostgreSQL (pgAdmin), Python, Tableau Public

Analysis by Manmeet Sodhi
