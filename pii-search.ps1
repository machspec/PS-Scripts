# Program:				Search For PII
# Date:					September 2021
# Programmers:			Trey Bentley and Mike Scott
#
# Description:			Script that is meant to be ran on a per computer
#	basis, this attempts to look in certain locations to find any sensitive 
#	Personally Identifiable Information. It then creates a report. At the
#	time of this writing, is does not remove any files, but might later on
#	down the road.		~TB 2021-09-01

# What C:\Users folders to check.
$foldersToCheck = `
	"Desktop", `
#	"OneDrive*\Desktop", `
#	"OneDrive*\Documents", `
#	"Downloads"
	"Documents"

# What File Types to check.
$ExtensionsToFilter = `
	"*.pdf", `
	"*.txt", `
	"*.csv", `
	"*.doc*", `
	"*.xls*"
	
# What RegExs to look out for
$regExs = @{}
$regExs['CreditCards'] = "(?:4[0-9]{12}(?:[0-9]{3})?|(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|6(?:011|5[0-9]{2})[0-9]{12}|(?:2131|1800|35\d{3})\d{11})"
$regExs['UsSsn'] = "\d{3}-\d{2}-\d{4}"
$regExs['BankAccount'] = "\d{10}"

$postUri = "https://piisvc.gtcc.edu/piiScanResult.php"


# For each Value in our custom folder list....
ForEach ($fldr in $foldersToCheck) {
	# Get all of the usernames in the C:\Users root.
	(Get-ChildItem -Path "C:\Users\").FullName | % {
		# Create a variable with the root plus the custom folder name. If may or may not be a path real, but that's okay.
		$usrFldrPath = "$_\$fldr"
		# If it is a real path....
		If (Test-Path "$usrFldrPath") {
			# .... Then get all files of the custom files types that've been custom defined.
			(Get-ChildItem "$usrFldrPath" -Recurse -Include $ExtensionsToFilter).FullName | % {
				# And give the result a more sensible variable name. 
				$fullFilePath = $_

				# Now, check the file for the different RegExs that we're looking for.
				ForEach ($key in $regExs.keys)  {
					$result = try { Select-String -Path "$fullFilePath" -Pattern $regExs[$key] -AllMatches -ErrorAction SilentlyContinue } catch {$false}

					# If a match was found that violates this PII policy ....
					If ($result) {
						$postData = @{
							piiType="$key"
							computer="$($env:COMPUTERNAME)"
							filePath="$fullFilePath"
							# We don't wnat to include the result, because then
							#	the result database becomes a violation spot,
							#	as well as any resulting report ran on it.
						}
						
						Invoke-RestMethod `
							-Uri $postUri `
							-Method Post `
							-Body $postData
						
						# And delete it
						# (????)
#						Remove-Item -Path "$fullFilePath" -Force -Confirm:$false -WhatIf
					}
				}
			}
		}
	}
}