Import-Module ActiveDirectory
$date = (Get-Date -Format "MM-dd-yyyy").toString() + "_password_last_set"

Get-ADUser -Filter * -Properties Enabled, SamAccountName, Name, createTimeStamp, Lastlogon, passwordlastset, displayname | Select-Object enabled, SamAccountName, Displayname, createtimestamp, @{Name = "LastLogon"; Expression = { [DateTime]::FromFileTime($_.lastlogon) } }, passwordlastset | Export-Csv .\$date.csv