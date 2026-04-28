import { Hono } from 'hono'
import { getPool } from '../db.js'

const stations = new Hono()

stations.get('/', async (c) => {
  const statut = c.req.query('statut')
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const whereClause = statut ? `WHERE s.statut = :statut` : ''
    const binds = statut ? { statut } : {}
    const result = await conn.execute(
      `SELECT
         s.code_station,
         s.nom_station,
         s.latitude,
         s.longitude,
         s.diametre_antenne,
         s.bande_frequence,
         s.debit_max,
         s.statut,
         COUNT(f.id_fenetre) AS nb_fenetres_total
       FROM STATION_SOL s
       LEFT JOIN FENETRE_COM f ON f.code_station = s.code_station
       ${whereClause}
       GROUP BY
         s.code_station, s.nom_station, s.latitude, s.longitude,
         s.diametre_antenne, s.bande_frequence, s.debit_max, s.statut
       ORDER BY s.code_station`,
      binds,
      { outFormat: 4002 }
    )
    return c.json(result.rows)
  } finally {
    await conn.close()
  }
})

stations.get('/:code', async (c) => {
  const code = c.req.param('code')
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const [stationResult, fenetreResult] = await Promise.all([
      conn.execute(
        `SELECT
           code_station, nom_station, latitude, longitude,
           diametre_antenne, bande_frequence, debit_max, statut
         FROM STATION_SOL
         WHERE code_station = :code`,
        { code },
        { outFormat: 4002 }
      ),
      conn.execute(
        `SELECT
           f.id_fenetre,
           f.datetime_debut,
           f.duree,
           f.elevation_max,
           f.volume_donnees,
           f.statut,
           f.id_satellite,
           s.nom_satellite
         FROM FENETRE_COM f
         JOIN SATELLITE s ON s.id_satellite = f.id_satellite
         WHERE f.code_station = :code
         ORDER BY f.datetime_debut DESC
         FETCH FIRST 20 ROWS ONLY`,
        { code },
        { outFormat: 4002 }
      ),
    ])

    if (!stationResult.rows || stationResult.rows.length === 0) {
      return c.json({ error: 'Station not found' }, 404)
    }

    const station = (stationResult.rows as Record<string, unknown>[])[0]
    return c.json({ ...station, fenetres: fenetreResult.rows })
  } finally {
    await conn.close()
  }
})

export default stations
