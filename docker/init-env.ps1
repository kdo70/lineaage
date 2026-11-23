$ErrorActionPreference = 'Stop'
$target = Join-Path (Split-Path $PSScriptRoot) '.env'
if (Test-Path -LiteralPath $target) { Write-Output '.env already exists; kept unchanged.'; return }
function New-HexToken {
    param([int]$Bytes = 24)
    return [Convert]::ToHexString([System.Security.Cryptography.RandomNumberGenerator]::GetBytes($Bytes)).ToLowerInvariant()
}
$content = "DB_PASSWORD=$(New-HexToken)`nDB_ROOT_PASSWORD=$(New-HexToken)`nGAME_HEX_ID=01$(New-HexToken -Bytes 15)`n"
[IO.File]::WriteAllText($target, $content, [Text.UTF8Encoding]::new($false))
Write-Output 'Created build/.env with local credentials.'
