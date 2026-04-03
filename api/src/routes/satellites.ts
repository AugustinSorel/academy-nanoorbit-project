import { Hono } from 'hono'
import { getPool } from '../db.js'

const satellites = new Hono()

// GET /satellites — list all satellites, optional ?statut= filter
// Uses v_satellites_operationnels for statut=Opérationnel, raw table otherwise
satellites.get('/', async (c) => {
  const statut = c.req.query('statut')
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    // v_satellites_operationnels already filters to Opérationnel satellites and
    // adds nb_instruments + etat_batterie — use it when that filter is requested
    // or when no filter is given (we union with the view for the operational ones)
    if (!statut || statut === 'Opérationnel') {
      const result = await conn.execute(
        `SELECT
           id_satellite,
           nom_satellite,
           format_cubesat,
           orbite,
           nb_instruments,
           capacite_batterie,
           etat_batterie
         FROM v_satellites_operationnels
         ORDER BY id_satellite`,
        {},
        { outFormat: 4002 }
      )
      return c.json(result.rows)
    }

    // For other statut filters, query the base table directly
    const result = await conn.execute(
      `SELECT
         s.id_satellite,
         s.nom_satellite,
         s.date_lancement,
         s.masse,
         s.format_cubesat,
         s.statut,
         s.duree_vie_prevue,
         s.capacite_batterie,
         s.id_orbite,
         o.type_orbite,
         o.altitude
       FROM SATELLITE s
       JOIN ORBITE o ON o.id_orbite = s.id_orbite
       WHERE s.statut = :statut
       ORDER BY s.id_satellite`,
      { statut },
      { outFormat: 4002 }
    )
    return c.json(result.rows)
  } finally {
    await conn.close()
  }
})

// GET /satellites/:id — single satellite with its instruments and missions
satellites.get('/:id', async (c) => {
  const id = c.req.param('id')
  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const [satResult, instrResult, missionResult, fenetreResult] = await Promise.all([
      conn.execute(
        `SELECT
           s.id_satellite,
           s.nom_satellite,
           s.date_lancement,
           s.masse,
           s.format_cubesat,
           s.statut,
           s.duree_vie_prevue,
           s.capacite_batterie,
           s.id_orbite,
           o.type_orbite,
           o.altitude,
           o.inclinaison,
           o.periode_orbitale,
           o.zone_couverture
         FROM SATELLITE s
         JOIN ORBITE o ON o.id_orbite = s.id_orbite
         WHERE s.id_satellite = :id`,
        { id },
        { outFormat: 4002 }
      ),
      conn.execute(
        `SELECT
           i.ref_instrument,
           i.type_instrument,
           i.modele,
           i.resolution,
           i.consommation,
           i.masse,
           e.date_integration,
           e.etat_fonctionnement
         FROM EMBARQUEMENT e
         JOIN INSTRUMENT i ON i.ref_instrument = e.ref_instrument
         WHERE e.id_satellite = :id
         ORDER BY i.ref_instrument`,
        { id },
        { outFormat: 4002 }
      ),
      conn.execute(
        `SELECT
           m.id_mission,
           m.nom_mission,
           m.statut_mission,
           m.date_debut,
           m.date_fin,
           p.role_satellite
         FROM PARTICIPATION p
         JOIN MISSION m ON m.id_mission = p.id_mission
         WHERE p.id_satellite = :id
         ORDER BY m.date_debut`,
        { id },
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
           f.code_station
         FROM FENETRE_COM f
         WHERE f.id_satellite = :id
         ORDER BY f.datetime_debut DESC
         FETCH FIRST 10 ROWS ONLY`,
        { id },
        { outFormat: 4002 }
      ),
    ])

    if (!satResult.rows || satResult.rows.length === 0) {
      return c.json({ error: 'Satellite not found' }, 404)
    }

    const satellite = (satResult.rows as Record<string, unknown>[])[0]
    return c.json({
      ...satellite,
      instruments: instrResult.rows,
      missions: missionResult.rows,
      recentFenetres: fenetreResult.rows,
    })
  } finally {
    await conn.close()
  }
})

// PATCH /satellites/:id/statut — update satellite status
satellites.patch('/:id/statut', async (c) => {
  const id = c.req.param('id')
  const body = await c.req.json<{ statut: string }>()
  const allowedStatuts = ['Opérationnel', 'En veille', 'Défaillant', 'Désorbité']

  if (!body.statut || !allowedStatuts.includes(body.statut)) {
    return c.json(
      { error: `statut must be one of: ${allowedStatuts.join(', ')}` },
      400
    )
  }

  const pool = await getPool()
  const conn = await pool.getConnection()
  try {
    const result = await conn.execute(
      `UPDATE SATELLITE SET statut = :statut WHERE id_satellite = :id`,
      { statut: body.statut, id },
      { autoCommit: true }
    )
    if (result.rowsAffected === 0) {
      return c.json({ error: 'Satellite not found' }, 404)
    }
    return c.json({ id_satellite: id, statut: body.statut })
  } finally {
    await conn.close()
  }
})

export default satellites
