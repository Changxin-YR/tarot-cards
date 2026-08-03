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

$bottomNavigationCheck = Join-Path $PSScriptRoot 'test_bottom_navigation_layout.py'
python $bottomNavigationCheck
if ($LASTEXITCODE -ne 0) {
  throw "Bottom navigation layout check failed with exit code $LASTEXITCODE"
}

$readingFlowExitCheck = Join-Path $PSScriptRoot 'test_reading_flow_exit.py'
python $readingFlowExitCheck
if ($LASTEXITCODE -ne 0) {
  throw "Reading flow exit check failed with exit code $LASTEXITCODE"
}

$homeGreetingCheck = Join-Path $PSScriptRoot 'test_home_greeting.py'
python $homeGreetingCheck
if ($LASTEXITCODE -ne 0) {
  throw "Home greeting check failed with exit code $LASTEXITCODE"
}

$appIconCheck = Join-Path $PSScriptRoot 'test_app_icon.py'
python $appIconCheck
if ($LASTEXITCODE -ne 0) {
  throw "Application icon check failed with exit code $LASTEXITCODE"
}

$reviewRemediationCheck = Join-Path $PSScriptRoot 'test_review_remediation.py'
python $reviewRemediationCheck
if ($LASTEXITCODE -ne 0) {
  throw "Review remediation regression check failed with exit code $LASTEXITCODE"
}

$themeAssetCheck = Join-Path $PSScriptRoot 'validate-theme-assets.ps1'
& $themeAssetCheck
if ($LASTEXITCODE -ne 0) {
  throw "Theme asset check failed with exit code $LASTEXITCODE"
}
