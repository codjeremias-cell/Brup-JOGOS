# =============================================================================
# Validador do pipeline de conteudo - Regras 1 a 7 da Seccao 8.3
# Uso: powershell -ExecutionPolicy Bypass -File tools\validate_cities.ps1
# Nota: manter este arquivo 100% ASCII (PS 5.1 le .ps1 sem BOM como ANSI).
# =============================================================================
$ErrorActionPreference = 'Stop'
$root     = Split-Path $PSScriptRoot -Parent
$citiesD  = Join-Path $root 'data\cities'
$poolFile = Join-Path $root 'data\pool\distractor_pool.json'

$script:failures = New-Object System.Collections.Generic.List[string]

function Fail($msg)   { $script:failures.Add($msg) }
function PassRule($n) { Write-Host ("  [OK] Regra {0}" -f $n) }

$files = Get-ChildItem $citiesD -Filter *.json
if ($files.Count -eq 0) { Fail 'Nenhuma cidade encontrada em data/cities' }

$cities = @()
foreach ($f in $files) { $cities += , (Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json) }

$poolIds = @{}
if (Test-Path $poolFile) {
  foreach ($p in ((Get-Content $poolFile -Raw | ConvertFrom-Json).cities)) { $poolIds[$p.city_id] = $true }
}
$cityIds = @{}
foreach ($c in $cities) { $cityIds[$c.city_id] = $true }

$tierMap = @{ low = 1; mid = 2; high = 3 }
$langs   = @('pt-BR','en-US','es')

# ---------- R1 Cobertura ----------
Write-Host ""
Write-Host "== Regra 1: cobertura (>=9 dicas, >=3/tier, >=4 categorias) =="
$r1ok = $true
foreach ($c in $cities) {
  $clues = @($c.clues)
  if ($clues.Count -lt 9) { Fail ("{0}: apenas {1} dicas" -f $c.city_id, $clues.Count); $r1ok = $false; continue }
  foreach ($t in @('low','mid','high')) {
    $n = @($clues | Where-Object { $_.tier -eq $t }).Count
    if ($n -lt 3) { Fail ("{0}: tier '{1}' com {2} dicas (<3)" -f $c.city_id, $t, $n); $r1ok = $false }
  }
  $cats = (@($clues | ForEach-Object category | Sort-Object -Unique)).Count
  if ($cats -lt 4) { Fail ("{0}: apenas {1} categorias" -f $c.city_id, $cats); $r1ok = $false }
}
if ($r1ok) { PassRule 1 }

# ---------- R2 Unicidade (identico + Jaccard > 0.70 entre cidades distintas) ----------
Write-Host "== Regra 2: unicidade entre cidades distintas (tier mid/high) =="
$r2ok = $true
foreach ($lang in $langs) {
  foreach ($a in $cities) {
    foreach ($ca in @($a.clues)) {
      if ($ca.tier -eq 'low') { continue }   # baixo pode ser ambiguo por desenho
      $rawA = [string]$ca.text.$lang
      $ta = @(($rawA.ToLower() -replace '[^\p{L}\p{Nd}\s]',' ') -split '\s+') | Where-Object { $_ }
      foreach ($b in $cities) {
        if ($b.city_id -eq $a.city_id) { continue }
        foreach ($cb in @($b.clues)) {
          if ($cb.tier -ne $ca.tier) { continue }
          $rawB = [string]$cb.text.$lang
          if ($rawA -eq $rawB) {
            Fail ("Texto identico [{0}/{1}] x [{2}/{3}]" -f $ca.clue_id, $lang, $cb.clue_id, $lang)
            $r2ok = $false; continue
          }
          $tb = @(($rawB.ToLower() -replace '[^\p{L}\p{Nd}\s]',' ') -split '\s+') | Where-Object { $_ }
          if (-not $ta -or -not $tb) { continue }
          $inter = @($ta | Where-Object { $tb -contains $_ }).Count
          $union = @(($ta + $tb) | Select-Object -Unique).Count
          if ($union -le 0) { continue }
          $j = $inter / $union
          if ($j -gt 0.70) {
            Fail ("Similaridade {0:P0} >70%: '{1}' x '{2}' ({3})" -f $j, $ca.clue_id, $cb.clue_id, $lang)
            $r2ok = $false
          }
        }
      }
    }
  }
}
if ($r2ok) { PassRule 2 }

# ---------- R3 Distratores (4-7, existentes, sem auto-referencia) ----------
Write-Host "== Regra 3: distratores =="
$r3ok = $true
foreach ($c in $cities) {
  $d = @($c.distractors)
  if ($d.Count -lt 4 -or $d.Count -gt 7) { Fail ("{0}: {1} distratores (esperado 4-7)" -f $c.city_id, $d.Count); $r3ok = $false; continue }
  foreach ($x in $d) {
    if ($x -eq $c.city_id) { Fail ("{0}: distrator aponta para si mesmo" -f $c.city_id); $r3ok = $false }
    if (-not ($cityIds.ContainsKey([string]$x) -or $poolIds.ContainsKey([string]$x))) {
      Fail ("{0}: distrator desconhecido '{1}'" -f $c.city_id, $x); $r3ok = $false
    }
  }
}
if ($r3ok) { PassRule 3 }

# ---------- R4 Sensibilidade + R5 Verificabilidade ----------
Write-Host "== Regras 4+5: sensibilidade e fonte do fato =="
$s45 = $true
foreach ($c in $cities) {
  foreach ($k in @($c.clues)) {
    if ($k.sensitivity_reviewed -ne $true) { Fail ("{0}/{1}: sensitivity_reviewed != true" -f $c.city_id, $k.clue_id); $s45 = $false }
    if ([string]::IsNullOrWhiteSpace([string]$k.fact_source)) { Fail ("{0}/{1}: fact_source vazio" -f $c.city_id, $k.clue_id); $s45 = $false }
    if ($tierMap[[string]$k.tier] -ne [int]$k.spoiler_level) { Fail ("{0}/{1}: spoiler_level incoerente com tier" -f $c.city_id, $k.clue_id); $s45 = $false }
    if (@('global','regional','continental') -notcontains [string]$k.uniqueness_scope) { Fail ("{0}/{1}: uniqueness_scope invalido" -f $c.city_id, $k.clue_id); $s45 = $false }
  }
}
if ($s45) { PassRule '4+5' }

# ---------- R6 i18n completo ----------
Write-Host "== Regra 6: i18n pt-BR/en-US/es completo =="
$i18nOk = $true
foreach ($c in $cities) {
  foreach ($lang in $langs) {
    if ([string]::IsNullOrWhiteSpace([string]$c.names.$lang))   { Fail ("{0}.names.{1} vazio" -f $c.city_id, $lang); $i18nOk = $false }
    if ([string]::IsNullOrWhiteSpace([string]$c.country.$lang)) { Fail ("{0}.country.{1} vazio" -f $c.city_id, $lang); $i18nOk = $false }
    if ([string]::IsNullOrWhiteSpace([string]$c.postcard.fun_fact.$lang)) { Fail ("{0}.postcard.fun_fact.{1} vazio" -f $c.city_id, $lang); $i18nOk = $false }
  }
  foreach ($k in @($c.clues)) {
    foreach ($lang in $langs) {
      if ([string]::IsNullOrWhiteSpace([string]$k.text.$lang)) { Fail ("{0}.text.{1} vazio" -f $k.clue_id, $lang); $i18nOk = $false }
      if (($null -ne $k.analysis) -and [string]::IsNullOrWhiteSpace([string]$k.analysis.$lang)) { Fail ("{0}.analysis.{1} vazio" -f $k.clue_id, $lang); $i18nOk = $false }
    }
  }
}
if ($i18nOk) { PassRule 6 }

# ---------- R7 Rastreabilidade clue_id ----------
Write-Host "== Regra 7: clue_id estaveis e unicos =="
$idOk = $true; $allIds = New-Object System.Collections.Generic.List[string]
foreach ($c in $cities) {
  foreach ($k in @($c.clues)) {
    $allIds.Add([string]$k.clue_id)
    if ($k.clue_id -notmatch ('^' + [regex]::Escape($c.city_id) + '-(low|mid|high)-\d{2}$')) {
      Fail ("clue_id fora do padrao: {0}" -f $k.clue_id); $idOk = $false
    }
  }
}
$dups = $allIds | Group-Object | Where-Object { $_.Count -gt 1 }
if ($dups) { foreach ($d in $dups) { Fail ("clue_id duplicado: {0}" -f $d.Name) }; $idOk = $false }
if ($idOk) { PassRule 7 }

# ---------- Estrutural extra ----------
Write-Host "== Estrutura: coordenadas / fuso / tier =="
$st = $true
foreach ($c in $cities) {
  if ([math]::Abs([double]$c.coords.lat) -gt 90 -or [math]::Abs([double]$c.coords.lon) -gt 180) { Fail ("{0}: coordenadas invalidas" -f $c.city_id); $st = $false }
  if (([string]$c.timezone) -notmatch '^America/') { Fail ("{0}: fuso fora de America/" -f $c.city_id); $st = $false }
  if (([int]$c.difficulty_tier) -lt 1 -or ([int]$c.difficulty_tier) -gt 5) { Fail ("{0}: difficulty_tier fora de 1..5" -f $c.city_id); $st = $false }
}
if ($st) { Write-Host '  [OK] estrutura' }

# ---------- Resumo ----------
Write-Host ""
if ($script:failures.Count -gt 0) {
  Write-Host ("FALHAS: {0}" -f $script:failures.Count) -ForegroundColor Red
  foreach ($f in $script:failures) { Write-Host (" - {0}" -f $f) -ForegroundColor Red }
  exit 1
}
else {
  Write-Host ("VALIDACAO COMPLETA: {0} cidades aprovadas nas 7 regras." -f $files.Count) -ForegroundColor Green
  exit 0
}
