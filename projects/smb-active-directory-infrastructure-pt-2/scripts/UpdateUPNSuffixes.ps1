$Users = Get-ADUser -Filter {UserPrincipalName -like '*ad.cooklab.com'} -Properties UserPrincipalName

ForEach ($u in $Users) {
    $newUPN = $u.UserPrincipalName.Replace("ad.cooklab.com", "mikecooklab.com")
    $u | Set-ADUser -UserPrincipalName $newUPN
}
