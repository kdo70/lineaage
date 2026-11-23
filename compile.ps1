$ErrorActionPreference = 'Stop'
if (-not $env:JAVA_HOME -or -not (Test-Path -LiteralPath "$env:JAVA_HOME/bin/javac.exe")) {
    throw 'Set JAVA_HOME to a JDK 21 or newer installation.'
}
$ant = Get-Command ant.bat -ErrorAction Stop
& $ant.Source -f (Join-Path $PSScriptRoot 'build.xml')
if ($LASTEXITCODE -ne 0) { throw "Build failed (exit code $LASTEXITCODE)." }
