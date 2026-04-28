import { Hono } from 'hono'
import { getPool } from '../db.js'

const stats = new Hono()

stats.get('/volumes', async (c) => {
  const station = c.req.query('station')
  const format = c.req.query('format')

  const conditions: string[] = []
  const binds: Record<string, string> = {}

  if (station) {
    conditions.push('code_station = :station')
    binds.station = station
  }
  if (format) {
    conditions.push('format_cubesat = :format')
    binds.format = format
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : ''

  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const result = await conn.execute(
      `SELECT
         TO_CHAR(mois, 'YYYY-MM') AS mois,
         code_station,
         nom_station,
         format_cubesat,
         nb_fenetres,
         volume_total_mo
       FROM mv_volumes_mensuels
       ${whereClause}
       ORDER BY mois, code_station, format_cubesat`,
      binds,
      { outFormat: 4002 }
    )
    return c.json(result.rows)
  } finally {
    await conn.close()
  }
})

stats.post('/volumes/refresh', async (c) => {
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    await conn.execute(
      `BEGIN DBMS_MVIEW.REFRESH('MV_VOLUMES_MENSUELS', 'C'); END;`,
      {},
      { autoCommit: true }
    )
    return c.json({ message: 'mv_volumes_mensuels refreshed successfully' })
  } finally {
    await conn.close()
  }
})

export default stats
