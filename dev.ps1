# Start / stop the whole app locally (Windows, no Docker).
#   dev            start backend (:8080) + frontend (:5173), logs in .\logs\
#   dev -Stop      stop both
#   dev -Restart   stop, then start
param([switch]$Stop, [switch]$Restart)

$ErrorActionPreference = 'Continue'
$root = $PSScriptRoot
$logs = Join-Path $root 'logs'
New-Item -ItemType Directory -Force $logs | Out-Null

function Stop-App {
    foreach ($name in 'backend', 'frontend') {
        $pidFile = Join-Path $logs "$name.pid"
        if (Test-Path $pidFile) {
            $procId = (Get-Content $pidFile | Select-Object -First 1).Trim()
            # /T kills the whole tree (cmd -> mvn -> java, cmd -> npm -> node)
            & taskkill /PID $procId /T /F 2>$null | Out-Null
            Remove-Item $pidFile -Force
            Write-Host "Stopped $name (pid $procId)"
        }
    }
}

function Test-Port([int]$port) {
    [bool](Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
}

function Wait-Url([string]$url, [int]$seconds) {
    $deadline = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $deadline) {
        try {
            Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 3 | Out-Null
            return $true
        } catch {
            if ($_.Exception.Response) { return $true }   # got an HTTP status => server is up
            Start-Sleep -Seconds 2
        }
    }
    return $false
}

if ($Stop) { Stop-App; exit 0 }
if ($Restart) { Stop-App; Start-Sleep -Seconds 2 }

foreach ($port in 8080, 5173) {
    if (Test-Port $port) {
        $owner = (Get-NetTCPConnection -LocalPort $port -State Listen | Select-Object -First 1).OwningProcess
        $procName = (Get-Process -Id $owner -ErrorAction SilentlyContinue).ProcessName
        Write-Host "Port $port is already in use by pid $owner ($procName)." -ForegroundColor Red
        Write-Host "If it's this app: dev -Stop. Otherwise: taskkill /PID $owner /F"
        exit 1
    }
}

if (-not (Test-Path (Join-Path $root 'frontend\node_modules'))) {
    Write-Host 'Installing frontend dependencies (first run)...'
    Push-Location (Join-Path $root 'frontend'); & npm.cmd install --no-audit --no-fund; Pop-Location
}

# Started through WMI (Win32_Process.Create) on purpose: the server processes must NOT inherit this
# shell's stdout/stderr handles, otherwise a caller piping our output (CI, an agent) waits forever.
function Start-Detached([string]$name, [string]$command, [string]$workDir) {
    $log = Join-Path $logs "$name.log"
    $err = Join-Path $logs "$name.err.log"
    $cmdLine = "cmd.exe /c `"$command > `"$log`" 2> `"$err`"`""
    $result = Invoke-CimMethod -ClassName Win32_Process -MethodName Create `
        -Arguments @{ CommandLine = $cmdLine; CurrentDirectory = $workDir }
    if ($result.ReturnValue -ne 0) { throw "Could not start $name (WMI code $($result.ReturnValue))" }
    $result.ProcessId | Set-Content (Join-Path $logs "$name.pid")
}

Write-Host 'Starting backend  -> logs\backend.log'
Start-Detached 'backend' 'mvn.cmd spring-boot:run' (Join-Path $root 'backend')

Write-Host 'Starting frontend -> logs\frontend.log'
Start-Detached 'frontend' 'npm.cmd run dev' (Join-Path $root 'frontend')

Write-Host 'Waiting for backend health (up to 120 s)...'
if (-not (Wait-Url 'http://localhost:8080/actuator/health' 120)) {
    Write-Host 'Backend did not come up. Check logs\backend.log or run: diagnose' -ForegroundColor Red
    exit 1
}
Write-Host 'Waiting for frontend (up to 60 s)...'
if (-not (Wait-Url 'http://localhost:5173/' 60)) {
    Write-Host 'Frontend did not come up. Check logs\frontend.log or run: diagnose' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'App running: http://localhost:5173' -ForegroundColor Green
Write-Host 'Stop with: ./dev.sh -Stop'
exit 0
