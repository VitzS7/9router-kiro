# rebuild-restart.ps1 — Para o 9router, faz build do CLI, e sobe de novo.
# Uso: powershell -ExecutionPolicy Bypass -File scripts\rebuild-restart.ps1

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot
$cliDir = Join-Path $repoRoot "cli"

Write-Host "1/4  Parando 9router..." -ForegroundColor Yellow
$procs = Get-CimInstance Win32_Process -Filter "CommandLine LIKE '%custom-server%' OR CommandLine LIKE '%9router%cli.js%'" -ErrorAction SilentlyContinue
foreach ($p in $procs) {
    Write-Host "     Kill PID $($p.ProcessId)"
    Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
}
# Aguarda liberar os arquivos
Start-Sleep -Seconds 2

Write-Host "2/4  Build do CLI..." -ForegroundColor Yellow
Push-Location $cliDir
try {
    npm run build
    if ($LASTEXITCODE -ne 0) { throw "Build failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}

Write-Host "3/4  Iniciando 9router..." -ForegroundColor Yellow
$globalCli = Join-Path $env:APPDATA "npm\9router.cmd"
if (Test-Path $globalCli) {
    Start-Process -FilePath "node" -ArgumentList (Join-Path $env:APPDATA "npm\node_modules\9router\cli.js") -WorkingDirectory $repoRoot -WindowStyle Hidden
} else {
    Start-Process -FilePath "node" -ArgumentList (Join-Path $cliDir "cli.js") -WorkingDirectory $repoRoot -WindowStyle Hidden
}
Start-Sleep -Seconds 3

Write-Host "4/4  Verificando..." -ForegroundColor Cyan
$check = Get-CimInstance Win32_Process -Filter "CommandLine LIKE '%custom-server%'" -ErrorAction SilentlyContinue
if ($check) {
    Write-Host "     9router rodando (PID $($check.ProcessId))" -ForegroundColor Green
} else {
    Write-Host "     AVISO: processo custom-server nao encontrado" -ForegroundColor Red
}
