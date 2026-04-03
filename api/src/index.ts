import process from 'node:process'

process.loadEnvFile(new URL('../.env', import.meta.url))

import { Hono } from 'hono'
import { serve } from '@hono/node-server'
import { getPool } from './db.js'

const app = new Hono()

app.get('/', (c) => {
  return c.json({ message: 'Hello World' })
})

app.get('/db-test', async (c) => {
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const result = await conn.execute<[string]>(
      `SELECT 'Oracle connection OK — ' || SYS_CONTEXT('USERENV','SESSION_USER') AS status FROM DUAL`
    )
    const status = result.rows?.[0][0]
    return c.json({ status })
  } finally {
    await conn.close()
  }
})

serve({ fetch: app.fetch, port: 3000 }, (info) => {
  console.log(`Server running at http://localhost:${info.port}`)
})
