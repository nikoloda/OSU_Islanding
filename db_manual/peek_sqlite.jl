# Print tables and the 10 most recent rows per table in the local SQLite DB.
# Run: julia db_manual/peek_sqlite.jl

cd(joinpath(@__DIR__, ".."))
include(joinpath(@__DIR__, "..", "src", "DB_SQLite.jl"))

conn = connect_sqlite()
peek_sqlite(conn)

try
    SQLite.close(conn)
catch e
    println("Warning closing DB: ", e)
end
