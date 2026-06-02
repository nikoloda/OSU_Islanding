# Must run in a terminal while the SSH tunnel is open

# LibPQ is a Julia wrapper for PostgreSQL which helps us use PostgreSQL and also connect to foreign instances
using LibPQ
# DataFrames is used for visualization in peek
using DataFrames

function connect_pg()
    # Prefer a full connection string, then fall back to standard libpq env vars.
    conn_str = get(ENV, "PG_CONN", "")
    if isempty(strip(conn_str))
        host = get(ENV, "PGHOST", "")
        port = get(ENV, "PGPORT", "")
        user = get(ENV, "PGUSER", "")
        dbname = get(ENV, "PGDATABASE", "")
        password = get(ENV, "PGPASSWORD", "")

        if any(isempty, (host, port, user, dbname, password))
            error("Set PG_CONN or PGHOST, PGPORT, PGUSER, PGDATABASE, and PGPASSWORD in your environment.")
        end

        conn_str = "host=$host port=$port user=$user dbname=$dbname password=$password"
    end
    
    conn = LibPQ.Connection(conn_str)
    println("Success! Connected through the tunnel.")

    return conn
end


function ensure_postgres_schema(conn)
    DB_create_records = """
        CREATE TABLE IF NOT EXISTS records (
            record_id SERIAL PRIMARY KEY,
            record_time TEXT NOT NULL,
            power_quality REAL,
            status INTEGER,
            bus_id INTEGER
        );
    """

    DB_create_global = """
        CREATE TABLE IF NOT EXISTS globalRecords (
            global_record_id SERIAL PRIMARY KEY,
            record_time TEXT NOT NULL UNIQUE,
            power_quality REAL,
            num_islands INTEGER,
            converges INTEGER
        );
    """

    execute(conn, DB_create_records)
    execute(conn, DB_create_global)
end


function insert_record_pg(conn, time_stamp, local_pq, converged_int, meter_bus_id)
    query = """
        INSERT INTO records(record_time, power_quality, status, bus_id)
        VALUES (\$1, \$2, \$3, \$4)
    """
    execute(conn, query, [time_stamp, local_pq, converged_int, meter_bus_id])
end


function insert_global_record_pg(conn, time_stamp, global_pq_avg, num_islands, converged_int)
    # Query the db to see if we already have a global entry using PostgreSQL syntax ($1)
    check_query = "SELECT COUNT(*) as count FROM globalRecords WHERE record_time = \$1"
    
    query_result = execute(conn, check_query, [time_stamp])
    
    # Extract the count from the LibPQ result
    existing_entry = first(query_result).count
    
    # If we do not have any entries at this time, we should add to the DB
    if existing_entry == 0
        insert_query = """
            INSERT INTO globalRecords (record_time, power_quality, num_islands, converges)
            VALUES (\$1, \$2, \$3, \$4)
        """
        # Execute using LibPQ syntax and the passed-in converged_int variable
        execute(conn, insert_query, [time_stamp, global_pq_avg, num_islands, converged_int])
    else
        println("Record for $time_stamp already exists. Skipping.")
    end
end


function peek_pg(conn)
    println("\n[PostgreSQL] Tables in Public Schema:")
    res_tables = execute(conn, "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public' ORDER BY tablename;")
    tables = DataFrame(res_tables)
    display(tables)

    for table_name in tables.tablename
        println("\n[PostgreSQL] First 10 rows of '$table_name':")
        safe_table = replace(table_name, "\"" => "\"\"")
        query = "SELECT * FROM \"$safe_table\" $(table_name == "records" ? "ORDER BY record_id DESC" : table_name == "globalRecords" ? "ORDER BY global_record_id DESC" : "") LIMIT 10;"
        res_data = execute(conn, query)
        display(DataFrame(res_data))
    end
end

function close_pg(conn)
    close(conn)
end

function clear_records_pg!(conn)
    println("[PostgreSQL] Deleting all rows from 'records' and 'globalRecords'")
    execute(conn, "TRUNCATE TABLE records, globalRecords RESTART IDENTITY;")
    return true
end

