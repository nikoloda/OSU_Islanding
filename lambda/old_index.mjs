import pg from 'pg';
const { Client } = pg;

export const handler = async (event) => {
    const client = new Client({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
        port: 5432,
        ssl: {
            rejectUnauthorized: false
        }
    });

    try {
        await client.connect();

        // 1. Extract both parameters sent from the frontend
        const requestedBusId = event.queryStringParameters?.bus_id;
        const targetTime = event.queryStringParameters?.target_time;

        // 2. Validate that both parameters were provided
        if (!requestedBusId || !targetTime) {
            return { 
                statusCode: 400, 
                body: JSON.stringify({ error: "Missing bus_id or target_time in URL parameters" }) 
            };
        }

        // 3. The SQL Magic: Order by the absolute time difference
        // We extract the 'epoch' (seconds since 1970) to do a clean mathematical subtraction
        const queryText = `
            SELECT * FROM records 
            WHERE bus_id = $1 
            ORDER BY ABS(EXTRACT(EPOCH FROM (record_time - $2::TIMESTAMP))) ASC 
            LIMIT 1;
        `;
        
        // 4. Pass both parameters in the array
        const res = await client.query(queryText, [requestedBusId, targetTime]);
        
        await client.end();

        return {
            statusCode: 200,
            body: JSON.stringify(res.rows),
        };

    } catch (err) {
        console.error('Database Error:', err);
        return { 
            statusCode: 500, 
            body: JSON.stringify({ error: "Failed to query the database" }) 
        };
    }
};