get-adcomputer -Filter * -Properties * | select enabled, DNSHostName, Name, createTimeStamp, PasswordLastSet,  | export-csv AllADUserDetails.csv