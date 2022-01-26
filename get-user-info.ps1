Import-Module ActiveDirectory
$date = (Get-Date -Format "MM-dd-yyyy").toString() + "_user_info"


Get-ADUser -filter * -properties memberof | Select-Object name,samaccountname,@{Name="MemberOf";Expression={$_.MemberOf -Join ";"}} | Export-Csv -Path .\$date.csv