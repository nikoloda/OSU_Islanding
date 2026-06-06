# OSU_Islanding
Most domestic smart meters have very limited computing power and thus lack the ability to perform detailed power grid analysis. The project team are working together, under the guidance of Dr. Eduardo Cotilla-Sanchez, to develop a GPU-accelerated smart meter alongside grid algorithms to allow for real-time analysis of large power grid cases.

## Project Layout
- `notebooks/` contains the analysis notebooks.
- `src/` contains the Julia helper modules for database work.
- `db_manual/` contains hand-run scripts to inspect or reset databases: `peek_sqlite.jl` / `clear_sqlite_records.jl` (local SQLite), `peek_postgres.jl` / `clear_postgres_records.jl` (AWS via `PG_*` env vars).
- `cases/` contains the MATPOWER case files used by the notebooks.

## Environment
- Use `.env` in the repo root for local configuration (`connect_pg()` loads it automatically).
- Set `PG_CONN` or `PGHOST`, `PGPORT`, `PGUSER`, `PGDATABASE`, `PGPASSWORD`.

## Synthetic Cases
Use `scripts/matpower_case_generator.jl` to write slightly perturbed MATPOWER cases into `data/generated_cases/`.
Example: `julia scripts/matpower_case_generator.jl 300 0 0.01` runs every 300 seconds, forever, with about 1% load noise.

Contact:
Daniel Nikolov - nikoloda@oregonstate.edu