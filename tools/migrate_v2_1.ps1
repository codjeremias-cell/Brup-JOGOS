# =============================================================================
# Migração de conteúdo v2.0 -> v2.1: adiciona utc_offset e language_family
# Uso: powershell -ExecutionPolicy Bypass -File tools\migrate_v2_1.ps1
# =============================================================================
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$dir  = Join-Path $root 'data\cities'
$utf8 = New-Object System.Text.UTF8Encoding($false)

$offsets = @{
  'bra-rio-de-janeiro'   = -3
  'bra-sao-paulo'        = -3
  'bra-salvador'         = -3
  'bra-manaus'           = -4
  'bra-ouro-preto'       = -3
  'mex-ciudad-de-mexico' = -6
  'mex-oaxaca'           = -6
  'mex-merida'           = -6
  'gtm-antigua'          = -6
  'nic-granada'          = -6
}
$fams = @{ 'pt' = 'romance'; 'es' = 'romance' }

Get-ChildItem $dir -Filter *.json | ForEach-Object {
  $txt  = [System.IO.File]::ReadAllText($_.FullName)
  $json = $txt | ConvertFrom-Json
  $id   = [string]$json.city_id
  $off  = $offsets[$id]
  $fam  = $fams[[string]($json.facts.languages[0])]
  if (-not $off) { throw "Sem offset mapeado para $id" }

  $tz = [string]$json.timezone
  $txt = [regex]::Replace($txt,
    ('("timezone"\s*:\s*"' + [regex]::Escape($tz) + '",)'),
    ('$1' + "`r`n" + '  "utc_offset": ' + $off + ','))

  $ctag = [string]$json.facts.climate_tag
  $txt = [regex]::Replace($txt,
    ('("climate_tag"\s*:\s*"' + [regex]::Escape($ctag) + '",)'),
    ('$1' + "`r`n" + '    "language_family": "' + $fam + '",'))

  [System.IO.File]::WriteAllText($_.FullName, $txt, $utf8)
  Write-Host ("{0}: utc_offset={1} language_family={2}" -f $id, $off, $fam)
}
Write-Host "Migracao v2.1 concluida."
