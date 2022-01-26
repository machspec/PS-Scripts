Import-Module ActiveDirectory
$date = (Get-Date -Format "MM-dd-yyyy").toString() + "_password_last_set"

get-aduser -Filter * -Properties Enabled, SamAccountName, Name, createTimeStamp, Lastlogon, passwordlastset, displayname | select enabled, SamAccountName, Displayname, createtimestamp, @{Name=”LastLogon”;Expression={[DateTime]::FromFileTime($_.lastlogon)}}, passwordlastset | export-csv .\$date.csv