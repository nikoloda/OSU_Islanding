# Peek, truncate records/globalRecords on AWS PostgreSQL, peek again.
# Requires PG_CONN or PGHOST, PGPORT, PGUSER, PGDATABASE, PGPASSWORD (SSH tunnel if needed).
# Run: julia db_manual/clear_postgres_records.jl

cd(joinpath(@__DIR__, ".."))
include(joinpath(@__DIR__, "..", "src", "DB_AWS_PostgreSQL.jl"))

conn = connect_pg()
peek_pg(conn)
clear_records_pg!(conn)
peek_pg(conn)
close_pg(conn)

println("clear_records_pg! completed")
