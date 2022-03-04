#need to do this so the date can match correctly to lastwritetime
$upperBound = [datetime]::ParseExact("12/31/2018", "MM/dd/yyyy", [CultureInfo]::InvariantCulture)
$lowerBound = [datetime]::ParseExact("01/01/2018", "MM/dd/yyyy", [CultureInfo]::InvariantCulture)

$source = "\\path\to\source"
$destination = "\\path\to\destination"

Get-ChildItem $source -file | Where-Object { $_.LastWriteTime -ge $lowerBound -and $_.LastWriteTime -le $upperBound } | ForEach-Object { Move-Item $_.FullName (Join-Path $destination $_.Name); Write-Output $_ }