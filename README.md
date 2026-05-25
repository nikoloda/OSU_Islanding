# OSU_Islanding
Most domestic smart meters have very limited computing power and thus lack the ability to perform detailed power grid analysis. The project team are working together, under the guidance of Dr. Eduardo Cotilla-Sanchez, to develop a GPU-accelerated smart meter alongside grid algorithms to allow for real-time analysis of large power grid cases.

## Project Layout
- `notebooks/` contains the analysis notebooks.
- `src/` contains the Julia helper modules for database work.
- `cases/` contains the MATPOWER case files used by the notebooks.

## Environment
- Use `.env` for local configuration.
- `PG_CONN` is used by `src/DB_AWS_PostgreSQL.jl`.

## Synthetic Cases
Use `scripts/matpower_case_generator.jl` to write slightly perturbed MATPOWER cases into `data/generated_cases/`.
Example: `julia scripts/matpower_case_generator.jl 300 0 0.01` runs every 300 seconds, forever, with about 1% load noise.

Contact:
Daniel Nikolov - nikoloda@oregonstate.edu