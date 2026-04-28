import { Hono } from 'hono'
import { getPool } from '../db.js'

const orbites = new Hono()

orbites.get('/', async (c) => {
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const result = await conn.execute(
      `SELECT
         o.id_orbite,
         o.type_orbite,
         o.altitude,
         o.inclinaison,
         o.periode_orbitale,
         o.excentricite,
         o.zone_couverture,
         COUNT(s.id_satellite) AS nb_satellites
       FROM ORBITE o
       LEFT JOIN SATELLITE s ON s.id_orbite = o.id_orbite
       GROUP BY
         o.id_orbite, o.type_orbite, o.altitude, o.inclinaison,
         o.periode_orbitale, o.excentricite, o.zone_couverture
       ORDER BY o.altitude`,
      {},
      { outFormat: 4002 }
    )
    return c.json(result.rows)
  } finally {
    await conn.close()
  }
})

orbites.get('/:id', async (c) => {
  const id = c.req.param('id')
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const [orbiteResult, satResult] = await Promise.all([
      conn.execute(
        `SELECT
           id_orbite, type_orbite, altitude, inclinaison,
           periode_orbitale, excentricite, zone_couverture
         FROM ORBITE
         WHERE id_orbite = :id`,
        { id },
        { outFormat: 4002 }
      ),
      conn.execute(
        `SELECT id_satellite, nom_satellite, statut, format_cubesat
         FROM SATELLITE
         WHERE id_orbite = :id
         ORDER BY id_satellite`,
        { id },
        { outFormat: 4002 }
      ),
    ])

    if (!orbiteResult.rows || orbiteResult.rows.length === 0) {
      return c.json({ error: 'Orbite not found' }, 404)
    }

    const orbite = (orbiteResult.rows as Record<string, unknown>[])[0]
    return c.json({ ...orbite, satellites: satResult.rows })
  } finally {
    await conn.close()
  }
})

export default orbites
