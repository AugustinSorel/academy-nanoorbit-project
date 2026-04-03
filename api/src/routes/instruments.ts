import { Hono } from 'hono'
import { getPool } from '../db.js'

const instruments = new Hono()

// GET /instruments — list all instruments
instruments.get('/', async (c) => {
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const result = await conn.execute(
      `SELECT
         i.ref_instrument,
         i.type_instrument,
         i.modele,
         i.resolution,
         i.consommation,
         i.masse,
         COUNT(e.id_satellite) AS nb_satellites
       FROM INSTRUMENT i
       LEFT JOIN EMBARQUEMENT e ON e.ref_instrument = i.ref_instrument
       GROUP BY
         i.ref_instrument, i.type_instrument, i.modele,
         i.resolution, i.consommation, i.masse
       ORDER BY i.ref_instrument`,
      {},
      { outFormat: 4002 }
    )
    return c.json(result.rows)
  } finally {
    await conn.close()
  }
})

// GET /instruments/:ref — single instrument with the satellites carrying it
instruments.get('/:ref', async (c) => {
  const ref = c.req.param('ref')
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const [instrResult, satResult] = await Promise.all([
      conn.execute(
        `SELECT ref_instrument, type_instrument, modele, resolution, consommation, masse
         FROM INSTRUMENT
         WHERE ref_instrument = :ref`,
        { ref },
        { outFormat: 4002 }
      ),
      conn.execute(
        `SELECT
           s.id_satellite,
           s.nom_satellite,
           s.statut,
           e.date_integration,
           e.etat_fonctionnement
         FROM EMBARQUEMENT e
         JOIN SATELLITE s ON s.id_satellite = e.id_satellite
         WHERE e.ref_instrument = :ref
         ORDER BY s.id_satellite`,
        { ref },
        { outFormat: 4002 }
      ),
    ])

    if (!instrResult.rows || instrResult.rows.length === 0) {
      return c.json({ error: 'Instrument not found' }, 404)
    }

    const instrument = (instrResult.rows as Record<string, unknown>[])[0]
    return c.json({ ...instrument, satellites: satResult.rows })
  } finally {
    await conn.close()
  }
})

export default instruments
