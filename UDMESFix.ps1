function FixXML {
	Param ($FilePath)
	[xml]$xml = Get-Content $FilePath
	$xml.configuration.appSettings.MESCustomMenuID.value = "UDMES"
	$xml.Save($FilePath)
}
If (Test-Path "C:\Epicor\GOV\Client\config\saas1029.sysconfig"){
    FixXML "C:\Epicor\GOV\Client\config\saas1029.sysconfig"
}
If (Test-Path "C:\Epicor\GOV\160829-LIVE\Client\config\saas1029.sysconfig") {
    FixXML "C:\Epicor\GOV\160829-LIVE\Client\config\saas1029.sysconfig"
}
