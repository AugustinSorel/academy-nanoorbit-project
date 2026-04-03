import oracledb from 'oracledb'

let pool: oracledb.Pool | null = null

export async function getPool(): Promise<oracledb.Pool> {
  if (!pool) {
    pool = await oracledb.createPool({
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      connectString: `${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_SERVICE}`,
    })
  }
  return pool
}
