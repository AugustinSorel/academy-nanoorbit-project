import process from 'node:process'

process.loadEnvFile(new URL('../.env', import.meta.url))

import { Hono } from 'hono'
import { serve } from '@hono/node-server'
import satellites from './routes/satellites.js'
import orbites from './routes/orbites.js'
import instruments from './routes/instruments.js'
import missions from './routes/missions.js'
import stations from './routes/stations.js'
import fenetres from './routes/fenetres.js'
import stats from './routes/stats.js'

const app = new Hono()

app.route('/satellites', satellites)
app.route('/orbites', orbites)
app.route('/instruments', instruments)
app.route('/missions', missions)
app.route('/stations', stations)
app.route('/fenetres', fenetres)
app.route('/stats', stats)

serve({ fetch: app.fetch, port: 3000 }, (info) => {
  console.log(`Server running at http://localhost:${info.port}`)
})
