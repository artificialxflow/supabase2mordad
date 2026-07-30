#!/usr/bin/env node
/**
 * Diagnostic wrapper for Runflare:
 * - prints safe env / bind info
 * - TCP-checks DATABASE_URL host
 * - starts Studio (inherited CMD)
 * - every 15s probes http://127.0.0.1:$PORT
 */
const http = require('http')
const net = require('net')
const { spawn } = require('child_process')

const PORT = process.env.PORT || '3000'
process.env.PORT = PORT
process.env.HOSTNAME = process.env.HOSTNAME || '0.0.0.0'

function maskDatabaseUrl(raw) {
  if (!raw) return '(empty)'
  try {
    const u = new URL(raw)
    if (u.password) u.password = '***'
    return u.toString()
  } catch {
    return '(invalid URL)'
  }
}

function logBanner() {
  console.log('========== DIAGNOSE START ==========')
  console.log(`[diagnose] time=${new Date().toISOString()}`)
  console.log(`[diagnose] HOSTNAME=${process.env.HOSTNAME}`)
  console.log(`[diagnose] PORT=${PORT}`)
  console.log(`[diagnose] SUPABASE_URL=${process.env.SUPABASE_URL || '(empty)'}`)
  console.log(`[diagnose] STUDIO_PG_META_URL=${process.env.STUDIO_PG_META_URL || '(empty)'}`)
  console.log(`[diagnose] DATABASE_URL=${maskDatabaseUrl(process.env.DATABASE_URL)}`)
  console.log(`[diagnose] cwd=${process.cwd()}`)
  console.log(`[diagnose] node=${process.version}`)
  console.log(`[diagnose] argv=${JSON.stringify(process.argv.slice(2))}`)
}

function tcpCheck(host, port, label, timeoutMs = 5000) {
  return new Promise((resolve) => {
    const socket = net.connect({ host, port: Number(port), timeout: timeoutMs })
    socket.on('connect', () => {
      console.log(`[diagnose] ${label} TCP OK ${host}:${port}`)
      socket.end()
      resolve(true)
    })
    socket.on('error', (err) => {
      console.log(`[diagnose] ${label} TCP FAIL ${host}:${port} -> ${err.message}`)
      resolve(false)
    })
    socket.on('timeout', () => {
      console.log(`[diagnose] ${label} TCP TIMEOUT ${host}:${port}`)
      socket.destroy()
      resolve(false)
    })
  })
}

async function checkDatabaseUrl() {
  const raw = process.env.DATABASE_URL
  if (!raw) {
    console.log('[diagnose] DATABASE_URL missing — Meta/DB features will fail')
    return
  }
  try {
    const u = new URL(raw)
    const host = u.hostname
    const port = u.port || '5432'
    console.log(`[diagnose] DB parsed host=${host} port=${port} db=${u.pathname}`)
    await tcpCheck(host, port, 'Postgres')
  } catch (err) {
    console.log(`[diagnose] DATABASE_URL parse error: ${err.message}`)
  }
}

function startLocalProbe() {
  let n = 0
  const tick = () => {
    n += 1
    const req = http.get(
      { host: '127.0.0.1', port: Number(PORT), path: '/', timeout: 3000 },
      (res) => {
        console.log(`[probe #${n}] 127.0.0.1:${PORT} -> HTTP ${res.statusCode}`)
        res.resume()
      }
    )
    req.on('error', (err) => {
      console.log(`[probe #${n}] 127.0.0.1:${PORT} FAIL -> ${err.message}`)
    })
    req.on('timeout', () => {
      console.log(`[probe #${n}] 127.0.0.1:${PORT} TIMEOUT`)
      req.destroy()
    })
  }
  setTimeout(tick, 5000)
  setInterval(tick, 15000)
}

function startStudio(args) {
  let cmd
  let cmdArgs

  if (args.length > 0) {
    cmd = args[0]
    cmdArgs = args.slice(1)
  } else if (require('fs').existsSync('/app/apps/studio/server.js')) {
    cmd = 'node'
    cmdArgs = ['/app/apps/studio/server.js']
  } else if (require('fs').existsSync('apps/studio/server.js')) {
    cmd = 'node'
    cmdArgs = ['apps/studio/server.js']
  } else {
    console.error('[diagnose] No CMD from image and no known Studio entry file')
    process.exit(1)
  }

  console.log(`[diagnose] starting: ${cmd} ${cmdArgs.join(' ')}`)
  console.log('========== DIAGNOSE END / STARTING STUDIO ==========')

  const child = spawn(cmd, cmdArgs, {
    stdio: 'inherit',
    env: process.env,
  })

  child.on('exit', (code, signal) => {
    console.log(`[diagnose] Studio exited code=${code} signal=${signal}`)
    if (signal) process.kill(process.pid, signal)
    process.exit(code ?? 1)
  })
}

async function main() {
  logBanner()
  await checkDatabaseUrl()
  startLocalProbe()
  startStudio(process.argv.slice(2))
}

main().catch((err) => {
  console.error('[diagnose] fatal', err)
  process.exit(1)
})
