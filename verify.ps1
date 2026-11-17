# One command that answers "does the whole app work?". Exit 0 = all green.
#   verify            backend tests, frontend typecheck + unit tests, smoke checks, e2e
#   verify -SkipE2E   skip the browser tests (faster inner loop)
param([switch]$SkipE2E)

$ErrorActionPreference = 'Continue'
$root = $PSScriptRoot
$results = New-Object System.Collections.Generic.List[object]
$script:failed = $false

function Run-Step([string]$name, [scriptblock]$block) {
    Write-Host "`n=== $name ===" -ForegroundColor Cyan
    $global:LASTEXITCODE = 0
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try {
        & $block
        $ok = ($LASTEXITCODE -eq 0)
    } catch {
        Write-Host $_ -ForegroundColor Red
        $ok = $false
    }
    $results.Add([pscustomobject]@{ Step = $name; Result = $(if ($ok) { 'PASS' } else { 'FAIL' }); Seconds = [int]$sw.Elapsed.TotalSeconds })
    if (-not $ok) { $script:failed = $true }
}

function Get-Status([string]$url) {
    try { return [int](Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 5).StatusCode }
    catch { if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode } else { return 0 } }
}

Run-Step 'Backend tests (mvn test)' {
    Push-Location (Join-Path $root 'backend')
    # clean: deleted/renamed classes must not linger in target/ and load at runtime
    try { & mvn.cmd -q clean test } finally { Pop-Location }
}

Run-Step 'Frontend typecheck (tsc)' {
    Push-Location (Join-Path $root 'frontend')
    try { & npm.cmd run --silent typecheck } finally { Pop-Location }
}

Run-Step 'Frontend unit tests (vitest)' {
    Push-Location (Join-Path $root 'frontend')
    try { & npm.cmd run --silent test } finally { Pop-Location }
}

Run-Step 'Smoke: app running, health, proxy' {
    if ((Get-Status 'http://localhost:8080/actuator/health') -ne 200 -or (Get-Status 'http://localhost:5173/') -ne 200) {
        Write-Host 'App not fully running; starting it with dev.ps1 -Restart'
        & (Join-Path $root 'dev.ps1') -Restart
        if ($LASTEXITCODE -ne 0) { throw 'dev.ps1 could not start the app' }
    }
    $health = Get-Status 'http://localhost:8080/actuator/health'
    $front = Get-Status 'http://localhost:5173/'
    $proxy = Get-Status 'http://localhost:5173/api/ping'   # 200 = Vite proxy reached Spring
    Write-Host "backend /actuator/health = $health (want 200)"
    Write-Host "frontend /               = $front (want 200)"
    Write-Host "proxy /api/ping          = $proxy (want 200)"
    if ($health -ne 200 -or $front -ne 200 -or $proxy -ne 200) { throw 'Smoke check failed' }
    $global:LASTEXITCODE = 0
}

if (-not $SkipE2E) {
    Run-Step 'E2E (playwright)' {
        Push-Location (Join-Path $root 'frontend')
        try { & npx.cmd playwright test } finally { Pop-Location }
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize | Out-String | Write-Host
if ($script:failed) {
    Write-Host 'VERIFY FAILED. Next: run ./diagnose.sh and follow the fullstack-doctor skill.' -ForegroundColor Red
    exit 1
}
Write-Host 'VERIFY PASSED' -ForegroundColor Green
exit 0
