# Program:		Purge Old Downloads
# Date:			November 2021
# Programmer:	Trey Bentley
# Description:	This script comes from the Great File Retension Mandate set by
#	the state in the 4th quarter of 2021. It attempts to delete and remove all
#	files and folders that are older than <time set by decision team>, from all
#	user's "Downloads" folder on a system.

#########################
#	Dynamic Variables
#########################
# These are profiles that shouldn't be looked at.
$excludeProfiles = @(
	"Public",
	"Adm1nGtcc"
)

# How many Days far backwards does the commitee want to start having stuff removed?
$days = 30

#########################
#	Logging Setup
#########################
# See if there's an eventlog for this script yet. Create one if not.
$logSrc = "Downloads Purge"
$logExist = [System.Diagnostics.EventLog]::SourceExists("$logSrc");
# Does the logging exist?
If (!($logExist)) {
	# No, let's create it.
	New-EventLog -LogName GTCC -Source "$logSrc"
	Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType Information -EventID 1215 -Message "New Application Source Log has been created."
}# Else: That's great! Nothing to create for the moment.
 # But now we can use line like:
 #	Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType Information -EventID 0 -Message "<MESSAGE HERE />"

#########################
#	Functions
#########################
Function chkData ($path) {
	# Getting data for the path coming in.
	$obj = Get-Item -Fo -Pa "$path"
	Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType Information -EventID 1612 -Message "Received Path: $path`n`nCommand:`n`t`$obj = Get-Item -Fo -Pa `"$path`"`nResult:`n$($obj | Select *)"
	$cnt['items']++
	# Does the data claim path is a Directory? Or, a File, instead?
	If ($obj.PSIsContainer) {	# It's a Directory!
		# Get the content of the Path, since it's a Directory.
		# Foreach obj in that directory, create the confusing circular logic of
		# sending to the same function that we're already in.....
		Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType Information -EventID 4918 -Message "This is a directory: $($obj.FullName)`nSending back round to delve a bit deeper`n`nNext Command:`n`tGet-ChildItem -Fo -Pa `"$($obj.FullName)`" | % { chkData `"$($_.FullName)`" }"
		Get-ChildItem -Fo -Pa "$($obj.FullName)" | % { chkData "$($_.FullName)" }
		
		Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType Information -EventID 5132 -Message "We've come back to: $($obj.FullName)`nChecking if empty or not`nContent Count: $((Get-ChildItem -Fo -Pa `"$($obj.FullName)`").Count)"
		# Get a fresh check on the directory again, to see if it's empty or not.
		If ((Get-ChildItem -Fo -Pa "$($obj.FullName)").Count -eq 0) {
			# If we made it into here, then it is empty. No sense in keeping
			# it. Let's remove this empty directory.
			Try {
				Remove-Item -Pa "$($obj.FullName)" -Co:$false -Fo -ErrorAction Stop
				$rs = "Success"
				$entType = "Information"
				$cnt['rmDir']++
			} Catch {
				$rs = $_
				$entType = "Error"
			} Finally {
				Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType $entType -EventID 1841 -Message "Directory:`n`t$($obj.FullName)`n...is empty and ready for removal.`nAttempted to delete.`n`nCommand:`n`tRemove-Item -Pa `"$($obj.FullName)`" -Co:$false -Fo -ErrorAction Stop`nResult:`n`t$rs"
			}
		}
	} ElseIf ($obj.CreationTime -lt $retDate) {
		# Welp! This is a File, and has been deemed worthy of deletions,
		# because it was created so long ago.
		# Leroy Jenkins!!!
		Try {
			Remove-Item -Pa "$($obj.FullName)" -Co:$false -Fo -ErrorAction Stop
			$rs = "Success"
			$entType = "Information"
			$cnt['rmFiles']++
		} Catch {
			$rs = $_
			$entType = "Error"
			$cnt['rmErr']++
		} Finally {
			Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType $entType -EventID 1869 -Message "File: $($obj.FullName)`nMet criteria for deleting.`nAttempted to delete.`n`nCommand:`n`tRemove-Item -Pa `"$($obj.FullName)`" -Co:$false -Fo -ErrorAction Stop`nResult:`n`t$rs"
		}
	}
}

#########################
#	Process
#########################

# Translate the how-many-days-ago day into a Retention Date
$retDate = (Get-Date).AddDays(-1 * $days)
Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType Information -EventID 4120 -Message "Looking for files created from before:`n`t$retDate"

# Let's keep a count of some things, like how many files/directories have been
#	looked at, and how many of those have been touched.
$global:cnt = @{}
$cnt['items'] = $cnt['rmFiles'] = $cnt['rmDir'] = $cnt['rmErr'] = 0

# Get a list of all the profiles in the root system directory.
Get-ChildItem -Pa "$($Env:HOMEDRIVE)\Users\" | % {

	# Confirm this account is not an exception.
	$skipIt = $false
	Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType Information -EventID 3811 -Message "Checking: $($_.Name)"
	ForEach ($exc in $excludeProfiles) {
		If ($_.Name -eq $exc) {
			$skipIt = $true
			Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType Information -EventID 5243 -Message "Actually, we'll be skipping this account profile, because it's on the exception list`n`t$($_.Name)"
		}
	}

	# If it's not an exception, then attempt to process this profile.
	If (!$skipIt) {
		# Build up the full path to look at.
		$dlPath = "$($_.FullName)\Downloads"
		Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType Information -EventID 2111 -Message "Delving into:`n`t$dlPath"
		# Does the path exist, or is at least accessible in the first the place at the moment?
		If (Test-Path "$dlPath" -ErrorAction SilentlyContinue) {
			# Call the function on each item inside the directory, if it is accessible.
			Get-ChildItem -Fo -Pa "$dlPath"| % { chkData "$($_.FullName)" }
		} Else {
			Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType Warning -EventID 1334 -Message "Path not found:`n`t$dlPath"
		}
	}
}

Write-EventLog -LogName GTCC -Source "$logSrc" -EntryType Information -EventID 2152 -Message "Totals:`n`tItems Assessed: $($cnt['items'])`n`tFiles Removed: $($cnt['rmFiles'])`n`tDirectories Removed: $($cnt['rmDir'])`n`tAttemted, but failed removals: $($cnt['rmErr'])"


# SIG # Begin signature block
# MIIR3gYJKoZIhvcNAQcCoIIRzzCCEcsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOhTr8VucXIuVQMBL8jQrO9xW
# wHKggg1DMIIDCDCCAfCgAwIBAgIQHfrJAMcndqFAFZ6Rrx1S1TANBgkqhkiG9w0B
# AQsFADAcMRowGAYDVQQDDBFHVENDIEF1dGhlbnRpY29kZTAeFw0yMTA5MzAxNTU1
# NTZaFw0yMjA5MzAxNjE1NTZaMBwxGjAYBgNVBAMMEUdUQ0MgQXV0aGVudGljb2Rl
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7/Qujm64IsgN4+MuLMUF
# 7UaZL1GR0msG2+AJn1UmPnrVpOvxm3hi8QRmDFBY79RqvK1YYmepz1RuV2eW7reT
# g8u8Qxa6T5z3QeRP3snpklWHwfamb5tCSwE6IIAehR7O17g95icgrWuzKpkKAeBL
# AUkJNM/AoD+pBhyXbz4+NUYAeFFom44WsGRP8iybOwUiOHbX0MeJqMVvib3ytdNg
# R4TJC6jhmBI8oDJSPt1ycGlv1QPg5inCMKTMIvEQlQFXQL6CpWQRA/LWms51khc5
# FLX4UJHCLgMaR2QM9xtMBbDQPDqKN9mAk4P1AbUNeE8Oi8kfF/rCgFmxNlSEZRIE
# EQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMw
# HQYDVR0OBBYEFNkWjY4McvJx0+dYav6HlZzVBw5LMA0GCSqGSIb3DQEBCwUAA4IB
# AQAPp3ghI/jzresYK3Bu/RMEnboxlRJhadSD6wDYKS3hSN0+zRY4VIOdhniwsl4C
# deVcPo1t70lwTnk1Z5z4+Oe5L3bg5HM+3H+C5ZkiKhQ1umoZmZ8xixpFWEnDsxoF
# yCj0UTaP1qF66WNEDAG2p/loDjtIJpU9WNVAn4H63NGgo554snCiQMkUw01H3W/3
# NExgO4ZUagNapn6X5qVpgF0wnPkyYBIkPpgFMQPNcdCNznlxyVC5sbPIKApKOOek
# fXMd5tJlJKwV7F1VX9PuCudHcQ0i9m1XIbLasogwWc+EYv62hF6Vj6OEZcbAlmbC
# CTqMnHAotam5Kcu3ufu1Lg5JMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw
# 3TANBgkqhkiG9w0BAQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdp
# Q2VydCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0YW1waW5nIENBMB4XDTIxMDEwMTAw
# MDAwMFoXDTMxMDEwNjAwMDAwMFowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRp
# Z2lDZXJ0LCBJbmMuMSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMLmYYRnxYr1DQikRcpja1HX
# OhFCvQp1dU2UtAxQtSYQ/h3Ib5FrDJbnGlxI70Tlv5thzRWRYlq4/2cLnGP9NmqB
# +in43Stwhd4CGPN4bbx9+cdtCT2+anaH6Yq9+IRdHnbJ5MZ2djpT0dHTWjaPxqPh
# Lxs6t2HWc+xObTOKfF1FLUuxUOZBOjdWhtyTI433UCXoZObd048vV7WHIOsOjizV
# I9r0TXhG4wODMSlKXAwxikqMiMX3MFr5FK8VX2xDSQn9JiNT9o1j6BqrW7EdMMKb
# aYK02/xWVLwfoYervnpbCiAvSwnJlaeNsvrWY4tOpXIc7p96AXP4Gdb+DUmEvQEC
# AwEAAaOCAbgwggG0MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMEEGA1UdIAQ6MDgwNgYJYIZIAYb9bAcBMCkwJwYI
# KwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAfBgNVHSMEGDAW
# gBT0tuEgHf4prtLkYaWyoiWyyBc1bjAdBgNVHQ4EFgQUNkSGjqS6sGa+vCgtHUQ2
# 3eNqerwwcQYDVR0fBGowaDAyoDCgLoYsaHR0cDovL2NybDMuZGlnaWNlcnQuY29t
# L3NoYTItYXNzdXJlZC10cy5jcmwwMqAwoC6GLGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0
# LmNvbS9zaGEyLWFzc3VyZWQtdHMuY3JsMIGFBggrBgEFBQcBAQR5MHcwJAYIKwYB
# BQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZDaHR0
# cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJRFRp
# bWVzdGFtcGluZ0NBLmNydDANBgkqhkiG9w0BAQsFAAOCAQEASBzctemaI7znGucg
# Do5nRv1CclF0CiNHo6uS0iXEcFm+FKDlJ4GlTRQVGQd58NEEw4bZO73+RAJmTe1p
# pA/2uHDPYuj1UUp4eTZ6J7fz51Kfk6ftQ55757TdQSKJ+4eiRgNO/PT+t2R3Y18j
# UmmDgvoaU+2QzI2hF3MN9PNlOXBL85zWenvaDLw9MtAby/Vh/HUIAHa8gQ74wOFc
# z8QRcucbZEnYIpp1FUL1LTI4gdr0YKK6tFL7XOBhJCVPst/JKahzQ1HavWPWH1ub
# 9y4bTxMd90oNcX6Xt/Q/hOvB46NJofrOp79Wz7pZdmGJX36ntI5nePk2mOHLKNpb
# h6aKLzCCBTEwggQZoAMCAQICEAqhJdbWMht+QeQF2jaXwhUwDQYJKoZIhvcNAQEL
# BQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJ
# RCBSb290IENBMB4XDTE2MDEwNzEyMDAwMFoXDTMxMDEwNzEyMDAwMFowcjELMAkG
# A1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRp
# Z2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIFRp
# bWVzdGFtcGluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL3Q
# Mu5LzY9/3am6gpnFOVQoV7YjSsQOB0UzURB90Pl9TWh+57ag9I2ziOSXv2MhkJi/
# E7xX08PhfgjWahQAOPcuHjvuzKb2Mln+X2U/4Jvr40ZHBhpVfgsnfsCi9aDg3iI/
# Dv9+lfvzo7oiPhisEeTwmQNtO4V8CdPuXciaC1TjqAlxa+DPIhAPdc9xck4Krd9A
# Oly3UeGheRTGTSQjMF287DxgaqwvB8z98OpH2YhQXv1mblZhJymJhFHmgudGUP2U
# Kiyn5HU+upgPhH+fMRTWrdXyZMt7HgXQhBlyF/EXBu89zdZN7wZC/aJTKk+FHcQd
# PK/P2qwQ9d2srOlW/5MCAwEAAaOCAc4wggHKMB0GA1UdDgQWBBT0tuEgHf4prtLk
# YaWyoiWyyBc1bjAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzASBgNV
# HRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEF
# BQcDCDB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHoweDA6oDig
# NoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9v
# dENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# QXNzdXJlZElEUm9vdENBLmNybDBQBgNVHSAESTBHMDgGCmCGSAGG/WwAAgQwKjAo
# BggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzALBglghkgB
# hv1sBwEwDQYJKoZIhvcNAQELBQADggEBAHGVEulRh1Zpze/d2nyqY3qzeM8GN0CE
# 70uEv8rPAwL9xafDDiBCLK938ysfDCFaKrcFNB1qrpn4J6JmvwmqYN92pDqTD/iy
# 0dh8GWLoXoIlHsS6HHssIeLWWywUNUMEaLLbdQLgcseY1jxk5R9IEBhfiThhTWJG
# JIdjjJFSLK8pieV4H9YLFKWA1xJHcLN11ZOFk362kmf7U2GJqPVrlsD0WGkNfMgB
# sbkodbeZY4UijGHKeZR+WfyMD+NvtQEmtmyl7odRIeRYYJu6DC0rbaLEfrvEJStH
# Agh8Sa4TtuF8QkIoxhhWz0E0tmZdtnR79VYzIi8iNrJLokqV2PWmjlIxggQFMIIE
# AQIBATAwMBwxGjAYBgNVBAMMEUdUQ0MgQXV0aGVudGljb2RlAhAd+skAxyd2oUAV
# npGvHVLVMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkG
# CSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEE
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBR0Fer432m+wY+qTCdJlYSAsN6V1jANBgkq
# hkiG9w0BAQEFAASCAQADk46JC7wxvu0NP0a+r7Ie78p7yj6fGR000E687oDiHcb6
# L9nZIVbh/qZJc2lsijKjBWRwQtxU1IF7tbWPceP3jC7gko5LhnTEst1gq73l4ziJ
# UaI3z2KsZ2XvXzghQz2BrnpMeO0LpScMmqKkvw+PTZyTaMTR3zuCWEd5GkF6dueQ
# Y7aZ1bthIBM8Y2lPajckcAMKnGM2NiXy/z8PzElAa1zovfzcGy8wzNlmUJjQMAYA
# 9EhsC1xVpM/KkYBILAOQhvD2W04DuN9Dvw8y3HFMSD0nBuVmYlRQ9EG0w0fqBgOv
# 3Dm8pTze2bRhRvY4XH41mdfZAKl8YNHVJNNnAlc1oYICMDCCAiwGCSqGSIb3DQEJ
# BjGCAh0wggIZAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lD
# ZXJ0IFNIQTIgQXNzdXJlZCBJRCBUaW1lc3RhbXBpbmcgQ0ECEA1CSuC+Ooj/YEAh
# zhQA8N0wDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcB
# MBwGCSqGSIb3DQEJBTEPFw0yMTA5MzAxNjA2MTdaMC8GCSqGSIb3DQEJBDEiBCAR
# A948aPvP3aBwJYOTK7AuIZd7xMquo7Z7vaL5BDj81TANBgkqhkiG9w0BAQEFAASC
# AQCEheuuckEwcDJCvGudWEcWa2y7KgDVwpEYija8y6EGPk4tthK8SeIc8ap2N9c9
# AoWfgP2ozdPWj/OH7NekZynwe9Vibwx8YVtfDAhuc5FmS4vNNONgrGilEZ9PshUu
# 8cYj7B6j7Tt/TcF4kKjf/grWnIh/zCnUFAR9V8QctrbjQCrKwg65FfT4HJsWlwe6
# d30J2pNoGiK7GRBCZMkDnlyAAWi95mWob4t9bZtDBMae3yI9uiQ62M2gX199Cgv4
# wfbf++gynT3SFpN4Z5JhY4ygiDuXcb5wb8ogfo/pjNjYAb6pqdNohjH4KpjLf2lh
# GJEquk2t6lvs5HHKznTtXpwB
# SIG # End signature block
