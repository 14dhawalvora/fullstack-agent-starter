# Read-only fact gathering for the fullstack-doctor skill. Changes nothing.
# Prints one section per layer: machine, processes, health, database, backend log, frontend log, last test results.

$ErrorActionPreference = 'Continue'
$root = $PSScriptRoot
$logs = Join-Path $root 'logs'

function Section([string]$title) { Write-Host "`n### $title" -ForegroundColor Cyan }

function Get-Status([string]$url) {
    try { return [int](Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 5).StatusCode }
    catch { if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode } else { return 0 } }
}

function Show-Errors([string]$file, [string]$pattern, [int]$max = 25) {
    if (-not (Test-Path $file)) { Write-Host "(no $file)"; return }
    $hits = Select-String -Path $file -Pattern $pattern -ErrorAction SilentlyContinue | Select-Object -Last $max
    if ($hits) { $hits | ForEach-Object { Write-Host ("{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) } }
    else { Write-Host "(no matches in $(Split-Path $file -Leaf))" }
}

Section 'Machine: tool versions'
cmd /c "java -version 2>&1" | Select-Object -First 1
cmd /c "mvn.cmd -v 2>&1" | Select-Object -First 1
Write-Host ("node " + (cmd /c "node -v 2>&1"))
Write-Host ("npm  " + (cmd /c "npm.cmd -v 2>&1"))

Section 'Machine: ports 8080 / 5173'
foreach ($port in 8080, 5173) {
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($conn) {
        $p = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        Write-Host "port $port LISTEN by pid $($conn.OwningProcess) ($($p.ProcessName))"
    } else {
        Write-Host "port $port free (nothing listening)"
    }
}

Section 'Processes started by dev.ps1'
foreach ($name in 'backend', 'frontend') {
    $pidFile = Join-Path $logs "$name.pid"
    if (Test-Path $pidFile) {
        $procId = (Get-Content $pidFile | Select-Object -First 1).Trim()
        $alive = [bool](Get-Process -Id $procId -ErrorAction SilentlyContinue)
        Write-Host "$name pid $procId alive=$alive"
    } else {
        Write-Host "${name}: no pid file (not started with dev.ps1, or stopped)"
    }
}

Section 'Health and routing'
$health = Get-Status 'http://localhost:8080/actuator/health'
Write-Host "backend  GET :8080/actuator/health -> $health (want 200)"
if ($health -eq 200 -or $health -eq 503) {
    try {
        $h = Invoke-RestMethod 'http://localhost:8080/actuator/health' -TimeoutSec 5
        Write-Host "         status=$($h.status) db=$($h.components.db.status) diskSpace=$($h.components.diskSpace.status)"
    } catch { }
}
Write-Host "backend  GET :8080/api/ping        -> $(Get-Status 'http://localhost:8080/api/ping') (want 200 = direct API ok)"
Write-Host "frontend GET :5173/                -> $(Get-Status 'http://localhost:5173/') (want 200)"
Write-Host "proxy    GET :5173/api/ping        -> $(Get-Status 'http://localhost:5173/api/ping') (want 200; 500/502/504 = proxy cannot reach backend)"

Section 'Database (H2 file)'
$db = Join-Path $root 'backend\data\appdb.mv.db'
if (Test-Path $db) { Write-Host ("db file exists, {0:N0} KB" -f ((Get-Item $db).Length / 1KB)) } else { Write-Host 'db file not created yet (backend never started successfully?)' }
if (Test-Path (Join-Path $root 'backend\data\appdb.lock.db')) { Write-Host 'lock file present (normal while backend runs; stale if backend is down)' }
Show-Errors (Join-Path $logs 'backend.log') 'o\.f\.core|FlywayException|Validate failed|checksum|Database may be already in use|JdbcSQL' 15

Section 'Backend log: errors (logs\backend.log)'
Show-Errors (Join-Path $logs 'backend.log') ' ERROR |Exception|Caused by|APPLICATION FAILED TO START|Port 8080 was already in use|BUILD FAILURE|COMPILATION ERROR' 30
Show-Errors (Join-Path $logs 'backend.err.log') '.' 15

Section 'Frontend log: errors (logs\frontend.log)'
Show-Errors (Join-Path $logs 'frontend.log') 'error|Error|failed|EADDRINUSE|ECONNREFUSED|proxy' 25
Show-Errors (Join-Path $logs 'frontend.err.log') '.' 15

Section 'Last backend test failures (surefire)'
$reports = Join-Path $root 'backend\target\surefire-reports'
if (Test-Path $reports) {
    $fails = Select-String -CaseSensitive -Path (Join-Path $reports '*.txt') -Pattern '<<< FAILURE|<<< ERROR|Failures: [1-9]|Errors: [1-9]' -ErrorAction SilentlyContinue
    if ($fails) { $fails | Select-Object -First 20 | ForEach-Object { Write-Host $_.Line.Trim() } } else { Write-Host 'no failures in last run' }
} else { Write-Host 'no surefire reports (backend tests not run yet)' }

Section 'Last e2e failures (playwright)'
$pw = Join-Path $root 'frontend\test-results'
if (Test-Path $pw) {
    Get-ChildItem $pw -Directory | Select-Object -First 10 | ForEach-Object { Write-Host "failed: $($_.Name)  (see error-context / trace inside)" }
} else { Write-Host 'no failed e2e artifacts' }

Write-Host "`nDone. Map the first abnormal line above to a layer, then follow .claude/skills/fullstack-doctor/SKILL.md"
