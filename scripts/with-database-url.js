#!/usr/bin/env node
/**
 * Parses DATABASE_URL and sets PG_META_* / POSTGRES_PASSWORD, then runs the real command.
 * Example:
 *   postgresql://postgres:secret@melkradardbnext-oft-service:5432/postgres
 */
const { spawn } = require('child_process')

function applyDatabaseUrl() {
  const raw = process.env.DATABASE_URL
  if (!raw || !String(raw).trim()) {
    console.error('[with-database-url] DATABASE_URL is required')
    process.exit(1)
  }

  let u
  try {
    u = new URL(raw)
  } catch (err) {
    console.error('[with-database-url] Invalid DATABASE_URL:', err.message)
    process.exit(1)
  }

  if (!/^postgres(ql)?:$/i.test(u.protocol)) {
    console.error('[with-database-url] DATABASE_URL must start with postgresql:// or postgres://')
    process.exit(1)
  }

  const dbName = decodeURIComponent(u.pathname.replace(/^\//, '').split('/')[0] || 'postgres')
  const password = decodeURIComponent(u.password || '')
  const user = decodeURIComponent(u.username || 'postgres')
  const host = u.hostname
  const port = u.port || '5432'

  if (!host) {
    console.error('[with-database-url] DATABASE_URL is missing host')
    process.exit(1)
  }

  process.env.PG_META_DB_HOST = host
  process.env.PG_META_DB_PORT = port
  process.env.PG_META_DB_USER = user
  process.env.PG_META_DB_PASSWORD = password
  process.env.PG_META_DB_NAME = dbName

  if (!process.env.POSTGRES_PASSWORD) {
    process.env.POSTGRES_PASSWORD = password
  }

  console.log(
    `[with-database-url] connected as ${user}@${host}:${port}/${dbName}`
  )
}

applyDatabaseUrl()

const args = process.argv.slice(2)
if (args.length === 0) {
  console.error('[with-database-url] No command provided')
  process.exit(1)
}

const child = spawn(args[0], args.slice(1), {
  stdio: 'inherit',
  env: process.env,
})

child.on('exit', (code, signal) => {
  if (signal) process.kill(process.pid, signal)
  process.exit(code ?? 1)
})
