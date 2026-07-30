[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$checker = 'C:\Users\27363\Desktop\harmonyos-project-standard-cn\scripts\check_harmonyos_standard.py'

if (-not (Test-Path -LiteralPath $checker -PathType Leaf)) {
  throw "HarmonyOS standard checker not found: $checker"
}

python $checker $projectRoot
if ($LASTEXITCODE -ne 0) {
  throw "HarmonyOS standard check failed with exit code $LASTEXITCODE"
}

