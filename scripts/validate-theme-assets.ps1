[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$mediaRoot = Join-Path $projectRoot 'entry\src\main\resources\base\media'
$themes = @('moon_garden', 'stained_glass')
$cardIds = New-Object System.Collections.Generic.List[string]

0..21 | ForEach-Object { $cardIds.Add(('major_{0:d2}' -f $_)) }
@('wands', 'cups', 'swords', 'pentacles') | ForEach-Object {
  $suit = $_
  1..14 | ForEach-Object { $cardIds.Add(('{0}_{1:d2}' -f $suit, $_)) }
}

Add-Type -AssemblyName System.Drawing
$errors = New-Object System.Collections.Generic.List[string]
foreach ($theme in $themes) {
  foreach ($cardId in $cardIds) {
    $path = Join-Path $mediaRoot ("${theme}_${cardId}.jpg")
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      $errors.Add("Missing: $path")
      continue
    }
    try {
      $image = [System.Drawing.Image]::FromFile($path)
      if ($image.Width -ne 600 -or $image.Height -ne 1000) {
        $errors.Add("Unexpected dimensions: $path ($($image.Width)x$($image.Height))")
      }
      $image.Dispose()
    }
    catch {
      $errors.Add("Unreadable: $path")
    }
  }
  $back = Join-Path $mediaRoot ("${theme}_card_back.jpg")
  if (-not (Test-Path -LiteralPath $back -PathType Leaf)) {
    $errors.Add("Missing: $back")
    continue
  }
  try {
    $image = [System.Drawing.Image]::FromFile($back)
    if ($image.Width -ne 600 -or $image.Height -ne 1000) {
      $errors.Add("Unexpected dimensions: $back ($($image.Width)x$($image.Height))")
    }
    $image.Dispose()
  }
  catch {
    $errors.Add("Unreadable: $back")
  }
}

if ($errors.Count -gt 0) {
  $errors | Select-Object -First 20 | ForEach-Object { Write-Error $_ -ErrorAction Continue }
  throw "Theme validation failed with $($errors.Count) error(s)."
}

python (Join-Path $PSScriptRoot 'test_import_tlp_decks.py')
if ($LASTEXITCODE -ne 0) {
  throw "Tarot image normalization validation failed with exit code $LASTEXITCODE"
}

Write-Host "Theme validation passed: $($themes.Count) themes, $($cardIds.Count) cards each, and one back each." -ForegroundColor Green
