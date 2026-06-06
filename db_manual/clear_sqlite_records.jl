# Peek, truncate records/globalRecords, peek again.
# Run: julia db_manual/clear_sqlite_records.jl

cd(joinpath(@__DIR__, ".."))
include(joinpath(@__DIR__, "..", "src", "DB_SQLite.jl"))

conn = connect_sqlite()
peek_sqlite(conn)
clear_records_sqlite(conn)
peek_sqlite(conn)

try
    SQLite.close(conn)
catch e
    println("Warning closing DB: ", e)
end

println("clear_records_sqlite completed")
