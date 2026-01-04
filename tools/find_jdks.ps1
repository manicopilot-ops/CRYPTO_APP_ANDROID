$roots = @(
  'C:\Program Files\Java',
  'C:\Program Files\Eclipse Adoptium',
  'C:\Program Files (x86)\Java',
  'C:\Program Files\Amazon Corretto',
  'C:\Program Files\Zulu',
  'C:\Program Files\AdoptOpenJDK'
)
$found = @()
foreach ($r in $roots) {
  if (Test-Path $r) {
    Get-ChildItem -Path $r -Directory -ErrorAction SilentlyContinue | ForEach-Object { $found += $_.FullName }
  }
}
if ($found.Count -eq 0) {
  Write-Output 'NO_JDK_FOUND'
} else {
  $found | Sort-Object | ForEach-Object { Write-Output $_ }
}
