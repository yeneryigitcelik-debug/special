import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool, query } from '../config/database.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function migrate(): Promise<void> {
  console.log('[Migrate] Starting database migrations...');

  // Create migrations tracking table if it doesn't exist
  await query(`
    CREATE TABLE IF NOT EXISTS _migrations (
      id SERIAL PRIMARY KEY,
      name TEXT UNIQUE NOT NULL,
      executed_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  // Read migration files
  const migrationsDir = path.join(__dirname, 'migrations');
  const files = fs
    .readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  for (const file of files) {
    // Check if already executed
    const existing = await query(
      'SELECT id FROM _migrations WHERE name = $1',
      [file]
    );

    if (existing.rows.length > 0) {
      console.log(`[Migrate] Skipping ${file} (already applied)`);
      continue;
    }

    // Read and execute the SQL
    const filePath = path.join(migrationsDir, file);
    const sql = fs.readFileSync(filePath, 'utf-8');

    console.log(`[Migrate] Applying ${file}...`);
    await query(sql);

    // Record the migration
    await query('INSERT INTO _migrations (name) VALUES ($1)', [file]);
    console.log(`[Migrate] Applied ${file}`);
  }

  console.log('[Migrate] All migrations complete.');
  await pool.end();
}

migrate().catch((err) => {
  console.error('[Migrate] Migration failed:', err);
  process.exit(1);
});
