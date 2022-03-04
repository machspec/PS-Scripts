$Computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

foreach ( $Computer in $Computers ) {
    Write-Host $Computer
    quser /server:$computer 2>&1
}