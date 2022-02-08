$Window_Title = "AD User Info"
Get-ADUser -Filter * -Properties * | Out-GridView -Title $Window_Title -OutputMode Multiple