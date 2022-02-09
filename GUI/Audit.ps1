# Converts the integer UAC value into something I can read.
Function DecodeUserAccountControl ([int]$UAC) {
    $UACPropertyFlags = @(
        "SCRIPT",
        "ACCOUNTDISABLE",
        "RESERVED",
        "HOMEDIR_REQUIRED",
        "LOCKOUT",
        "PASSWD_NOTREQD",
        "PASSWD_CANT_CHANGE",
        "ENCRYPTED_TEXT_PWD_ALLOWED",
        "TEMP_DUPLICATE_ACCOUNT",
        "NORMAL_ACCOUNT",
        "RESERVED",
        "INTERDOMAIN_TRUST_ACCOUNT",
        "WORKSTATION_TRUST_ACCOUNT",
        "SERVER_TRUST_ACCOUNT",
        "RESERVED",
        "RESERVED",
        "DONT_EXPIRE_PASSWORD",
        "MNS_LOGON_ACCOUNT",
        "SMARTCARD_REQUIRED",
        "TRUSTED_FOR_DELEGATION",
        "NOT_DELEGATED",
        "USE_DES_KEY_ONLY",
        "DONT_REQ_PREAUTH",
        "PASSWORD_EXPIRED",
        "TRUSTED_TO_AUTH_FOR_DELEGATION",
        "RESERVED",
        "PARTIAL_SECRETS_ACCOUNT"
        "RESERVED"
        "RESERVED"
        "RESERVED"
        "RESERVED"
        "RESERVED"
    )
    return (0..($UACPropertyFlags.Length) | Where-Object { $UAC -bAnd [math]::Pow(2, $_) } | ForEach-Object { $UACPropertyFlags[$_] }) -join ” | ”
}


# Audit Last time computer password was refreshed
Get-ADComputer -Filter * -Properties * |
Select-Object enabled, DNSHostName, Name, createTimeStamp, PasswordLastSet, 
@{Name = "LastLogon"; Expression = { [DateTime]::FromFileTime($_.lastlogon) } }, 
UserAccountControl,
@{Name = "UserAccountControl-Translated"; Expression = { DecodeUserAccountControl $_.UserAccountControl } } |
Out-GridView -Title "Computer Audit"


# Audit user groups, time of last password change, and time of last login
Get-ADUser -Filter * -Properties * |
Select-Object Enabled, SamAccountName, Name, Displayname, PrimaryGroup, MemberOf, PasswordLastSet, 
@{Name = "LastLogon"; Expression = { [DateTime]::FromFileTime($_.lastlogon) } }, createTimeStamp, logonCount, 
UserAccountControl,
@{Name = "UserAccountControl-Translated"; Expression = { DecodeUserAccountControl $_.UserAccountControl } } |
Out-GridView -Title "User Audit"