# Print public tables and up to 10 rows each on AWS PostgreSQL.
# Requires PG_CONN or PGHOST, PGPORT, PGUSER, PGDATABASE, PGPASSWORD (SSH tunnel if needed).
# Run: julia db_manual/peek_postgres.jl

cd(joinpath(@__DIR__, ".."))
include(joinpath(@__DIR__, "..", "src", "DB_AWS_PostgreSQL.jl"))

conn = connect_pg()
peek_pg(conn)
close_pg(conn)
