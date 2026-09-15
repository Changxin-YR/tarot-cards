[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$requiredPaths = @(
  'AGENTS.md',
  'README.md',
  'tasks.md',
  'changes.md',
  'design.md',
  'design-qa.md',
  'build-profile.json5',
  'entry/src/main/module.json5',
  'entry/src/main/resources/base/profile/main_pages.json',
  'entry/src/main/ets'
)
foreach ($relativePath in $requiredPaths) {
  $fullPath = Join-Path $projectRoot $relativePath
  if (-not (Test-Path -LiteralPath $fullPath)) {
    throw "Required project path is missing: $relativePath"
  }
}

$moduleText = Get-Content -LiteralPath (Join-Path $projectRoot 'entry/src/main/module.json5') -Raw
if ($moduleText -notmatch '"type"\s*:\s*"entry"' -or
    $moduleText -notmatch '"mainElement"\s*:\s*"EntryAbility"' -or
    $moduleText -notmatch '"pages"\s*:\s*"\$profile:main_pages"') {
  throw 'Entry module metadata is incomplete'
}
$pages = Get-Content -LiteralPath (Join-Path $projectRoot 'entry/src/main/resources/base/profile/main_pages.json') -Raw | ConvertFrom-Json
if (-not $pages -or -not $pages.src -or $pages.src.Count -eq 0) {
  throw 'main_pages.json does not declare any pages'
}
Write-Output "Local HarmonyOS gate passed: $($requiredPaths.Count) required paths and entry metadata"

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

$appIdentityCheck = Join-Path $PSScriptRoot 'test_app_identity.py'
python $appIdentityCheck
if ($LASTEXITCODE -ne 0) {
  throw "Application identity check failed with exit code $LASTEXITCODE"
}

$reviewRemediationCheck = Join-Path $PSScriptRoot 'test_review_remediation.py'
python $reviewRemediationCheck
if ($LASTEXITCODE -ne 0) {
  throw "Review remediation regression check failed with exit code $LASTEXITCODE"
}

$appGalleryFollowupCheck = Join-Path $PSScriptRoot 'test_appgallery_followup.py'
python $appGalleryFollowupCheck
if ($LASTEXITCODE -ne 0) {
  throw "AppGallery follow-up regression check failed with exit code $LASTEXITCODE"
}

$themeAssetCheck = Join-Path $PSScriptRoot 'validate-theme-assets.ps1'
& $themeAssetCheck
if ($LASTEXITCODE -ne 0) {
  throw "Theme asset check failed with exit code $LASTEXITCODE"
}
