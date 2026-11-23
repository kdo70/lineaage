$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'docker/init-env.ps1')
& (Join-Path $PSScriptRoot 'compile.ps1')
$dockerBin = 'C:\Program Files\Docker\Docker\resources\bin'
if (Test-Path -LiteralPath $dockerBin) { $env:PATH = "$dockerBin;$env:PATH" }
Push-Location $PSScriptRoot
try {
    $compose = 'C:\Program Files\Docker\Docker\resources\cli-plugins\docker-compose.exe'
    if (Test-Path -LiteralPath $compose) { & $compose up -d --build }
    else { docker compose up -d --build }
    if ($LASTEXITCODE -ne 0) { throw 'Docker Compose startup failed.' }
} finally { Pop-Location }
