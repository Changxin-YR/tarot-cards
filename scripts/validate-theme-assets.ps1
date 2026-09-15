[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$mediaRoot = Join-Path $projectRoot 'entry\src\main\resources\base\media'
$requiredAssets = @(
  @{ Name = 'card_placeholder.png'; Width = 1024; Height = 1536 },
  @{ Name = 'card_back.png'; Width = 1024; Height = 1536 }
)

Add-Type -AssemblyName System.Drawing
$errors = New-Object System.Collections.Generic.List[string]
foreach ($asset in $requiredAssets) {
  $path = Join-Path $mediaRoot $asset.Name
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $errors.Add("Missing: $path")
    continue
  }
  try {
    $image = [System.Drawing.Image]::FromFile($path)
    if ($image.Width -ne $asset.Width -or $image.Height -ne $asset.Height) {
      $errors.Add("Unexpected dimensions: $path ($($image.Width)x$($image.Height))")
    }
    $image.Dispose()
  }
  catch {
    $errors.Add("Unreadable: $path")
  }
}

if ($errors.Count -gt 0) {
  $errors | ForEach-Object { Write-Error $_ -ErrorAction Continue }
  throw "Neutral media validation failed with $($errors.Count) error(s)."
}

Write-Host "Neutral media validation passed: $($requiredAssets.Count) local reflection assets." -ForegroundColor Green
