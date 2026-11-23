$ErrorActionPreference = 'Stop'
$project = Split-Path (Split-Path $PSScriptRoot)
& "$env:JAVA_HOME/bin/javac.exe" -encoding UTF-8 -cp "$project/dist/gameserver/libs/*" -d $PSScriptRoot "$PSScriptRoot/GatekeeperSmoke.java"
if ($LASTEXITCODE -ne 0) { throw 'Smoke compilation failed' }
Push-Location "$project/dist/gameserver"
try {
 & "$env:JAVA_HOME/bin/java.exe" -cp "$PSScriptRoot;libs/*" GatekeeperSmoke
 if ($LASTEXITCODE -ne 0) { throw 'Gatekeeper smoke failed' }
} finally { Pop-Location }
