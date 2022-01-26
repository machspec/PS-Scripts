get-aduser -Filter * -Properties Enabled, SamAccountName, Name, Title, createTimeStamp, Lastlogon, PasswordLastSet, PasswordNeverExpires, CannotChangePassword, PasswordNotRequired, LastBadPasswordAttempt, userAccountControl | select enabled, SamAccountName, Name, createtimestamp, @{Name=”LastLogon”;Expression={[DateTime]::FromFileTime($_.lastlogon)}}, PasswordLastSet, LastBadPasswordAttempt, PasswordNeverExpires, CannotChangePassword, PasswordNotRequired, userAccountControl  | export-csv AllADUserDetails.csv