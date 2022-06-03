# Program:          Generate new user names
# Date:             June 2022
# Author:           odjacobs
# Description:      
# Create new usernames based on the format fistname.lastname@domain.name

# get the desired domain name from the user
$domain_name = Read-Host("Enter the domain name")
# get a list of active directory user accounts and store them in an array
$Users = Get-ADUser -Filter * -Properties *
# loop through the array and display the user's first and last name
foreach ($user in $Users) {
    $new_name = $user.givenName + "." + $user.sn
    # if $new_name ends with a period, remove it
    if ($new_name.EndsWith(".")) {
        $new_name = $new_name.Substring(0, $new_name.Length - 1)
    }
    $new_name = $new_name + "@" + $domain_name
    # convert $new_name to lowercase
    $new_name = $new_name.ToLower()
    # if $new_name does not equal $domain_name print $new_name
    if ($new_name -ne "@$domain_name") {
        Write-Host $new_name
    }
}
