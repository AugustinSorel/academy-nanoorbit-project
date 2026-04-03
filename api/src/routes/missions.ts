import { Hono } from 'hono'
import { getPool } from '../db.js'

const missions = new Hono()

// GET /missions — list all missions, optional ?statut= filter
// Uses v_stats_missions which adds nb_satellites, types_orbites, volume_total_mo
missions.get('/', async (c) => {
  const statut = c.req.query('statut')
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const whereClause = statut ? `WHERE v.statut_mission = :statut` : ''
    const binds = statut ? { statut } : {}
    const result = await conn.execute(
      `SELECT
         v.id_mission,
         v.nom_mission,
         v.statut_mission,
         v.nb_satellites,
         v.types_orbites,
         v.volume_total_mo,
         m.objectif,
         m.zone_geo_cible,
         m.date_debut,
         m.date_fin
       FROM v_stats_missions v
       JOIN MISSION m ON m.id_mission = v.id_mission
       ${whereClause}
       ORDER BY m.date_debut DESC`,
      binds,
      { outFormat: 4002 }
    )
    return c.json(result.rows)
  } finally {
    await conn.close()
  }
})

// GET /missions/:id — single mission with participating satellites
missions.get('/:id', async (c) => {
  const id = c.req.param('id')
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const [missionResult, satResult] = await Promise.all([
      conn.execute(
        `SELECT id_mission, nom_mission, objectif, zone_geo_cible,
                date_debut, date_fin, statut_mission
         FROM MISSION
         WHERE id_mission = :id`,
        { id },
        { outFormat: 4002 }
      ),
      conn.execute(
        `SELECT
           s.id_satellite,
           s.nom_satellite,
           s.statut,
           s.format_cubesat,
           p.role_satellite
         FROM PARTICIPATION p
         JOIN SATELLITE s ON s.id_satellite = p.id_satellite
         WHERE p.id_mission = :id
         ORDER BY s.id_satellite`,
        { id },
        { outFormat: 4002 }
      ),
    ])

    if (!missionResult.rows || missionResult.rows.length === 0) {
      return c.json({ error: 'Mission not found' }, 404)
    }

    const mission = (missionResult.rows as Record<string, unknown>[])[0]
    return c.json({ ...mission, satellites: satResult.rows })
  } finally {
    await conn.close()
  }
})

export default missions
