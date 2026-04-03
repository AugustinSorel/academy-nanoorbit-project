import { Hono } from 'hono'
import { getPool } from '../db.js'

const fenetres = new Hono()

// GET /fenetres — list communication windows
// Uses v_fenetres_detail which provides duree_formatee and volume_affiche
// Query params: ?statut=, ?satellite=, ?station=
fenetres.get('/', async (c) => {
  const statut = c.req.query('statut')
  const satellite = c.req.query('satellite')
  const station = c.req.query('station')

  const conditions: string[] = []
  const binds: Record<string, string> = {}

  if (statut) {
    conditions.push('statut_fenetre = :statut')
    binds.statut = statut
  }
  if (satellite) {
    conditions.push('id_satellite = :satellite')
    binds.satellite = satellite
  }
  if (station) {
    conditions.push('code_station = :station')
    binds.station = station
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : ''

  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const result = await conn.execute(
      `SELECT
         id_fenetre,
         datetime_debut,
         id_satellite,
         nom_satellite,
         code_station,
         nom_station,
         bande_frequence,
         duree,
         duree_formatee,
         elevation_max,
         volume_donnees,
         volume_affiche,
         statut_fenetre
       FROM v_fenetres_detail
       ${whereClause}
       ORDER BY datetime_debut DESC`,
      binds,
      { outFormat: 4002 }
    )
    return c.json(result.rows)
  } finally {
    await conn.close()
  }
})

// GET /fenetres/:id — single communication window via v_fenetres_detail
fenetres.get('/:id', async (c) => {
  const id = c.req.param('id')
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const result = await conn.execute(
      `SELECT
         id_fenetre,
         datetime_debut,
         id_satellite,
         nom_satellite,
         code_station,
         nom_station,
         bande_frequence,
         duree,
         duree_formatee,
         elevation_max,
         volume_donnees,
         volume_affiche,
         statut_fenetre
       FROM v_fenetres_detail
       WHERE id_fenetre = :id`,
      { id },
      { outFormat: 4002 }
    )

    if (!result.rows || result.rows.length === 0) {
      return c.json({ error: 'Fenetre not found' }, 404)
    }

    return c.json((result.rows as Record<string, unknown>[])[0])
  } finally {
    await conn.close()
  }
})

export default fenetres
