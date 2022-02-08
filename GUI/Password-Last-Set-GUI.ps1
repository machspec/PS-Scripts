$Window_Title = "Password Last Set"
Get-ADUser -Filter * -Properties Enabled, SamAccountName, Name, createTimeStamp, Lastlogon, passwordlastset, displayname | Select-Object enabled, SamAccountName, Displayname, createtimestamp, @{Name = "LastLogon"; Expression = { [DateTime]::FromFileTime($_.lastlogon) } }, passwordlastset | Out-GridView -Title $Window_Title -OutputMode Multiple