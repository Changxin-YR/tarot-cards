[CmdletBinding()]
param(
  [Alias('Mode')]
  [ValidateSet('debug', 'release')]
  [string]$BuildMode = 'debug',
  [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$localHvigor = Join-Path $projectRoot 'hvigorw.bat'
$hvigorCommand = $null

if (Test-Path -LiteralPath $localHvigor -PathType Leaf) {
  $hvigorCommand = $localHvigor
}
else {
  $hvigor = Get-Command 'hvigorw.bat' -ErrorAction SilentlyContinue
  if ($null -ne $hvigor) {
    $hvigorCommand = $hvigor.Source
  }
}

if ($null -eq $hvigorCommand) {
  $bundled = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
  if (Test-Path -LiteralPath $bundled -PathType Leaf) {
    $hvigorCommand = $bundled
  }
}

if ($null -eq $hvigorCommand) {
  throw 'hvigorw.bat was not found.'
}

Push-Location $projectRoot
try {
  if ($Clean) {
    & $hvigorCommand clean --no-daemon
    if ($LASTEXITCODE -ne 0) {
      throw "HarmonyOS clean failed with exit code $LASTEXITCODE"
    }
  }

  & $hvigorCommand assembleHap --no-daemon --mode module -p product=default -p "buildMode=$BuildMode"
  if ($LASTEXITCODE -ne 0) {
    throw "HarmonyOS build failed with exit code $LASTEXITCODE"
  }

  $buildRoot = Join-Path $projectRoot 'entry\build'
  $artifact = Get-ChildItem -LiteralPath $buildRoot -Recurse -File -Filter '*.hap' |
    Sort-Object LastWriteTimeUtc -Descending |
    Select-Object -First 1

  if ($null -eq $artifact) {
    throw "Build succeeded, but no HAP was found below: $buildRoot"
  }

  Write-Host 'HarmonyOS build passed.' -ForegroundColor Green
  Write-Host "Artifact: $($artifact.FullName)"
  Write-Host "Size: $($artifact.Length) bytes"
}
finally {
  Pop-Location
}

