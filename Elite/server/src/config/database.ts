import pg from 'pg';
import { config } from './env.js';

const pool = new pg.Pool({
  connectionString: config.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  console.error('Unexpected PostgreSQL pool error:', err);
});

export async function query<T extends pg.QueryResultRow = pg.QueryResultRow>(
  text: string,
  params?: unknown[]
): Promise<pg.QueryResult<T>> {
  const start = Date.now();
  const result = await pool.query<T>(text, params);
  const duration = Date.now() - start;

  if (config.NODE_ENV === 'development') {
    console.log('[DB] Query executed', {
      text: text.substring(0, 80),
      duration: `${duration}ms`,
      rows: result.rowCount,
    });
  }

  return result;
}

export async function getClient(): Promise<pg.PoolClient> {
  const client = await pool.connect();
  return client;
}

export { pool };
