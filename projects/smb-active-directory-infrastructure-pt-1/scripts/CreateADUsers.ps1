Import-Module ActiveDirectory

$CsvPath = Read-Host -Prompt "Enter the full path to the users CSV file"
Write-Host "`n"

$Users = Import-Csv -Path $CsvPath

# Default initial password - not used in production
$Password = ConvertTo-SecureString "Networklab!312" -AsPlainText -Force

foreach ($user in $Users) {
    New-ADUser -Name $user.name `
     -DisplayName $user.Name `
     -Department $user.Department `
     -Title $user.Title `
     -Description $user.Title `
     -UserPrincipalName $user.UserPrincipalName `
     -SamAccountName $user.SamAccountName `
     -PasswordNeverExpires $true `
     -ChangePasswordAtLogon $false `
     -AccountPassword $Password `
     -Enabled $true

    $u = Get-ADUser -Identity $user.SamAccountName
    $group = $user.Department + " Dept"
    $dept = $user.Department
    
    Add-ADGroupMember -Identity "CN=$group,OU=$dept,OU=Employees,DC=ad,DC=cooklab,DC=com" -Members $u.DistinguishedName

    Move-ADObject -Identity $u.DistinguishedName -TargetPath "OU=Users,OU=$dept,OU=Employees,DC=ad,DC=cooklab,DC=com"
}