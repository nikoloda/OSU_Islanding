using SQLite
using DBInterface
using DataFrames
function connect_sqlite()
    return SQLite.DB("test_simple_grid_database.sqlite")
end

function ensure_sqlite_schema(conn)
    DBInterface.execute(conn, """
        CREATE TABLE IF NOT EXISTS records (
            record_id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_time TEXT NOT NULL,
            power_quality REAL,
            status INTEGER,
            bus_id INTEGER
        )
    """)

    DBInterface.execute(conn, """
        CREATE TABLE IF NOT EXISTS globalRecords (
            global_record_id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_time TEXT NOT NULL UNIQUE,
            power_quality REAL,
            num_islands INTEGER,
            converges INTEGER
        )
    """)
end

function insert_record_sqlite(conn, time_stamp, local_pq, converged_int, meter_bus_id)
    query = """
        INSERT INTO records(record_time, power_quality, status, bus_id)
        VALUES (?, ?, ?, ?)
    """
    DBInterface.execute(conn, query, [time_stamp, local_pq, converged_int, meter_bus_id])
end

function insert_global_record_sqlite(conn, time_stamp, global_pq_avg, num_islands, converged_int)
    # Query the db to see if we already have a global entry at the time step of the file
    
    check_query = "SELECT COUNT(*) as count FROM globalRecords WHERE record_time = ?"
    
    # current_time = Dates.format(Dates.now(), "yyyy-mm-dd HH:MM:SS")
    
    query_result = DBInterface.execute(conn, check_query, [time_stamp])
     
    # Extract the value from the first row, if there is one
    existing_entry = first(query_result)
    
    
    # If we do not have any entries at this time, we should add to the DB
    if existing_entry.count == 0
        DBInterface.execute(conn, """
            INSERT INTO globalRecords (record_time, power_quality, num_islands, converges)
            VALUES (?, ?, ?, ?)
        """, [time_stamp, global_pq_avg, num_islands, converged_int])
    else
        println("Record for $time_stamp already exists. Skipping.")
    end

    
end

function peek_sqlite(conn)
    println("\n[SQLite] Tables in Database:")
    # SQLite uses sqlite_master to list tables instead of pg_catalog
    res_tables = DBInterface.execute(conn, "SELECT name as tablename FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;")
    tables = DataFrame(res_tables)
    display(tables)

    for table_name in tables.tablename
        println("\n[SQLite] Most recent 10 rows of '$table_name':")
        safe_table = replace(table_name, "\"" => "\"\"")
        order_clause = table_name == "records" ? "ORDER BY record_id DESC" : table_name == "globalRecords" ? "ORDER BY global_record_id DESC" : "ORDER BY rowid DESC"
        query = "SELECT * FROM \"$safe_table\" $order_clause LIMIT 10;"
        res_data = DBInterface.execute(conn, query)
        display(DataFrame(res_data))
    end
end

function clear_records_sqlite(conn)
    println("[SQLite] Deleting all rows from 'records' and 'globalRecords'")
    DBInterface.execute(conn, "DELETE FROM records;")
    DBInterface.execute(conn, "DELETE FROM globalRecords;")
    return true
end