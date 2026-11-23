"""Convert the raw ICE Excel files to clean CSVs for Postgres.
- skips ICE's title rows above the header
- snake_case column names
- Excel serial dates -> YYYY-MM-DD (date) / YYYY-MM-DD HH:MM:SS (datetime)
Run: python3 scripts/xlsx_to_csv.py   (from the deportation-data folder)
"""
import csv, glob, re, datetime as dt, openpyxl, sys

EPOCH = dt.datetime(1899, 12, 30)
DATE_COLS = {'apprehension_date', 'departed_date', 'final_order_date', 'entry_date',
             'msc_charge_date', 'msc_conviction_date'}
DATETIME_COLS = {'apprehension_date'}

def snake(s):
    return re.sub(r'[^a-z0-9]+', '_', str(s).strip().lower()).strip('_')

def fix_date(v, keep_time):
    if v in (None, ''):
        return ''
    if isinstance(v, dt.datetime):
        d = v
    else:
        try:
            d = EPOCH + dt.timedelta(days=float(v))
        except ValueError:
            return str(v)
    return d.strftime('%Y-%m-%d %H:%M:%S' if keep_time else '%Y-%m-%d')

def convert(files, out, header_hint, extra=None):
    n = 0
    with open(out, 'w', newline='') as fo:
        w = csv.writer(fo)
        wrote_header = False
        for f in files:
            ws = openpyxl.load_workbook(f, read_only=True, data_only=True).worksheets[0]
            cols = None
            for row in ws.iter_rows(values_only=True):
                if cols is None:
                    if row and header_hint in [str(c) for c in row]:
                        cols = [snake(c) if c else f'col_{i}' for i, c in enumerate(row)]
                        if not wrote_header:
                            w.writerow(cols + ([extra[0]] if extra else []))
                            wrote_header = True
                    continue
                if not any(row):
                    continue
                vals = []
                for c, v in zip(cols, row):
                    if c in DATE_COLS:
                        vals.append(fix_date(v, c in DATETIME_COLS))
                    else:
                        vals.append('' if v is None else v)
                if extra:
                    vals.append(extra[1](f))
                w.writerow(vals)
                n += 1
            print(f'{f}: done ({n:,} rows so far)', flush=True)
    print(f'-> {out}: {n:,} rows', flush=True)

# Usage: python3 scripts/xlsx_to_csv.py arrests FY2025   |   python3 scripts/xlsx_to_csv.py removals
which = sys.argv[1]
if which == 'arrests':
    fy = sys.argv[2]
    convert(glob.glob(f'data/raw/arrests_*/*{fy}*.xlsx'), f'data/clean/arrests_{fy}.csv',
            'Apprehension Criminality', extra=('source_file_fy', lambda f: fy[2:]))
elif which == 'removals':
    convert(glob.glob('data/raw/removals_*/*.xlsx'), 'data/clean/removals_jul2025.csv', 'Departed Date')
