# Must run in terminal while open s

# LibPQ is a Julia wrapper for PostgreSQL which helps us use PostgreSQL and also connect to foreign instances
using LibPQ
# DataFrames is used for visualization in peek
using DataFrames

function connect_pg()
    # Connect to the tunnel entrance on your own machine
    conn_str = "host=localhost port=5433 user=testnikoloda dbname=postgres password=___"
    
    conn = LibPQ.Connection(conn_str)
    println("Success! Connected through the tunnel.")

    return conn
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
    res_tables = execute(conn, "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public';")
    display(DataFrame(res_tables))

    println("\n[PostgreSQL] First 10 rows of 'buses' table:")
    res_data = execute(conn, "SELECT * FROM buses LIMIT 10;")
    display(DataFrame(res_data))
end

function close_pg(conn)
    close(conn)
end

