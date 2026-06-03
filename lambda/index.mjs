import pg from 'pg';

const { Client } = pg;

const CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json',
};

/**
 * Matches GridPing DB_AWS_PostgreSQL.jl uploads.
 * DB column record_time: TEXT, Julia format → YYYY-MM-DD HH24:MI:SS
 *
 * Frontend message params:
 *   query        required — latest_bus | bus_24h | latest_global | last_outage
 *   target_time  required — YYYY-MM-DD HH:mm:ss (time the user is viewing)
 *   bus_id       required for latest_bus, bus_24h, last_outage
 * 
 * record_time in rows is the DB timestamp per reading; target_time is what the frontend sent.
 */

// Functions which run inside of the SQL queries

// Time from DB record_time column
const DB_RECORD_TIME = `to_timestamp(record_time, 'YYYY-MM-DD HH24:MI:SS')`;

// Supported query types the frontend can send
export const QUERY_TYPES = {
    LATEST_BUS: 'latest_bus',
    BUS_24H: 'bus_24h',
    LATEST_GLOBAL: 'latest_global',
    LAST_OUTAGE: 'last_outage',
};

const QUERIES = {
    /**
     * Order by most recent records to target time and take the closest
     * Params: bus_id, target_time
     */
    [QUERY_TYPES.LATEST_BUS]: {
        requiredParams: ['bus_id', 'target_time'],
        sql: `
            SELECT record_id, record_time, power_quality, status, bus_id
            FROM records
            WHERE bus_id = $1
            ORDER BY ABS(${DB_RECORD_TIME} - to_timestamp($2, 'YYYY-MM-DD HH24:MI:SS')) ASC
            LIMIT 1;
        `,
        params: (queryParams) => [
            Number(queryParams.bus_id),
            queryParams.target_time,
        ],
    },

    /**
     * Order by most recent records to target time and take all records from last 24 hours
     * Params: bus_id, target_time
     */
    [QUERY_TYPES.BUS_24H]: {
        requiredParams: ['bus_id', 'target_time'],
        sql: `
            SELECT record_id, record_time, power_quality, status, bus_id
            FROM records
            WHERE bus_id = $1
              AND ${DB_RECORD_TIME} > to_timestamp($2, 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '24 hours'
              AND ${DB_RECORD_TIME} <= to_timestamp($2, 'YYYY-MM-DD HH24:MI:SS')
            ORDER BY ${DB_RECORD_TIME} DESC;
        `,
        params: (queryParams) => [
            Number(queryParams.bus_id),
            queryParams.target_time,
        ],
    },

    /**
     * Order by most recent global_records to target time and take the closest
     * Params: target_time
     */
    [QUERY_TYPES.LATEST_GLOBAL]: {
        requiredParams: ['target_time'],
        sql: `
            SELECT global_record_id, record_time, power_quality, num_islands, converges
            FROM globalrecords
            ORDER BY ABS(${DB_RECORD_TIME} - to_timestamp($1, 'YYYY-MM-DD HH24:MI:SS')) ASC
            LIMIT 1;
        `,
        params: (queryParams) => [queryParams.target_time],
    },

    /**
     * Order by most recent records to target time and select the last record with an outage
     * Params: bus_id, target_time
     */
    [QUERY_TYPES.LAST_OUTAGE]: {
        requiredParams: ['bus_id', 'target_time'],
        sql: `
            SELECT record_id, record_time, power_quality, status, bus_id
            FROM records
            WHERE bus_id = $1
              AND status = 0
              AND ${DB_RECORD_TIME} <= to_timestamp($2, 'YYYY-MM-DD HH24:MI:SS')
            ORDER BY ${DB_RECORD_TIME} DESC
            LIMIT 1;
        `,
        params: (queryParams) => [
            Number(queryParams.bus_id),
            queryParams.target_time,
        ],
    },
};

function jsonResponse(statusCode, body) {
    return {
        statusCode,
        headers: CORS_HEADERS,
        body: JSON.stringify(body),
    };
}

// Connect to the database
function createDbClient() {
    return new Client({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
        port: 5432,
        ssl: {
            rejectUnauthorized: false,
        },
    });
}


export const handler = async (event) => {
    // Listen until we recieve parameters for a query
    const queryParams = event.queryStringParameters ?? {};

    // Get the specific type of query, hopefully from our list of supported queries
    const queryType = queryParams.query;

    // Return an error if not supported
    if (!queryType || !QUERIES[queryType]) {
        return jsonResponse(400, {
            error: 'Missing or invalid query parameter',
            query: queryType ?? null,
            supported: Object.values(QUERY_TYPES),
        });
    }

    const definition = QUERIES[queryType];

    // Create a new client to connect to the database
    const client = createDbClient();

    // Try to execute the query
    try {
        await client.connect();

        const values = definition.params(queryParams);

        // Execute the query
        const result = await client.query(definition.sql, values);

        // Return the results to the frontend
        return jsonResponse(200, {
            query: queryType,
            target_time: queryParams.target_time,
            count: result.rows.length,
            rows: result.rows,
        });
    } catch (err) {
        console.error('Database Error:', err);
        return jsonResponse(500, { error: 'Failed to query the database' });
    } finally {
        // Close DB connection
        await client.end().catch(() => {});
    }
};
