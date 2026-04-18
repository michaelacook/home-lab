Import-Module ActiveDirectory

# THIS IS A WORK IN PROGRESS!
# Works so far. Need to create privileged accounts
# Need to make code more DRY

### CREATE IT GROUPS

New-ADGroup -GroupCategory Security -GroupScope Global -Name "Service Desk Techs" -Path "OU=IT,DC=ad,DC=cooklab,DC=com"
New-ADGroup -GroupCategory Security -GroupScope Global -Name "1st Line Support" -Path "OU=IT,DC=ad,DC=cooklab,DC=com"
New-ADGroup -GroupCategory Security -GroupScope Global -Name "2nd Line Support" -Path "OU=IT,DC=ad,DC=cooklab,DC=com"
New-ADGroup -GroupCategory Security -GroupScope Global -Name "3rd Line Support" -Path "OU=IT,DC=ad,DC=cooklab,DC=com"

### CREATE IT DEPT USERS

# Default initial password - not used in production
$Password = ConvertTo-SecureString "Networklab!312" -AsPlainText -Force

New-ADUser -Name "Jen Barber" `
  -DisplayName "Jen Barber" `
  -Department "IT" `
  -Path "OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com" `
  -Title "Director of IT" `
  -Description "Director of IT" `
  -UserPrincipalName "jen.barber@ad.cooklab.com" `
  -SamAccountName "jen.barber" `
  -PasswordNeverExpires $true `
  -ChangePasswordAtLogon $false `
  -AccountPassword $Password `
  -Enabled $true

New-ADUser -Name "Michael Cook" `
  -DisplayName "Michael Cook" `
  -Department "IT" `
  -Manager "CN=Jen Barber,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com" `
  -Path "OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com" `
  -Title "Network Administrator" `
  -Description "Network Administrator" `
  -UserPrincipalName "michael.cook@ad.cooklab.com" `
  -SamAccountName "michael.cook" `
  -PasswordNeverExpires $true `
  -ChangePasswordAtLogon $false `
  -AccountPassword $Password `
  -Enabled $true

New-ADUser -Name "Olivia Lajoie" `
  -DisplayName "Olivia Lajoie" `
  -Department "IT" `
  -Manager "CN=Jen Barber,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com" `
  -Path "OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com" `
  -Title "System Administrator" `
  -Description "System Administrator" `
  -UserPrincipalName "olivia.lajoie@ad.cooklab.com" `
  -SamAccountName "olivia.lajoie" `
  -PasswordNeverExpires $true `
  -ChangePasswordAtLogon $false `
  -AccountPassword $Password `
  -Enabled $true

New-ADUser -Name "Ramon Jackson" `
  -DisplayName "Ramon Jackson" `
  -Department "IT" `
  -Manager "CN=Olivia Lajoie,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com" `
  -Path "OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com" `
  -Title "Service Desk Analyst II" `
  -Description "Service Desk Analyst II" `
  -UserPrincipalName "ramon.jackson@ad.cooklab.com" `
  -SamAccountName "ramon.jackson" `
  -PasswordNeverExpires $true `
  -ChangePasswordAtLogon $false `
  -AccountPassword $Password `
  -Enabled $true

New-ADUser -Name "Jamie Perkins" `
  -DisplayName "Ramon Jackson" `
  -Department "IT" `
  -Manager "CN=Olivia Lajoie,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com" `
  -Path "OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com" `
  -Title "Service Desk Analyst I" `
  -Description "Service Desk Analyst I" `
  -UserPrincipalName "jamie.perkins@ad.cooklab.com" `
  -SamAccountName "jamie.perkins" `
  -PasswordNeverExpires $true `
  -ChangePasswordAtLogon $false `
  -AccountPassword $Password `
  -Enabled $true

New-ADUser -Name "Agnes Chan" `
  -DisplayName "Agnes Chan" `
  -Department "IT" `
  -Manager "CN=Michael Cook,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com" `
  -Path "OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com" `
  -Title "Infrastructure Technician" `
  -Description "Infrastructure Technician" `
  -UserPrincipalName "agnes.chan@ad.cooklab.com" `
  -SamAccountName "agnes.chan" `
  -PasswordNeverExpires $true `
  -ChangePasswordAtLogon $false `
  -AccountPassword $Password `
  -Enabled $true

# Create privileged accounts

# ADD GROUP MEMBERSHIPS

Add-ADGroupMember -Identity "CN=IT Dept,OU=IT,DC=ad,DC=cooklab,DC=com" -Members `
  "CN=Jen Barber,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Michael Cook,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Olivia Lajoie,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Ramon Jackson,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Jamie Perkins,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Agnes Chan,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com"

Add-ADGroupMember -Identity "CN=1st Line Support,OU=IT,DC=ad,DC=cooklab,DC=com" -Members `
  "CN=Michael Cook,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Olivia Lajoie,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Ramon Jackson,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Jamie Perkins,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Agnes Chan,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com"

Add-ADGroupMember -Identity "CN=2nd Line Support,OU=IT,DC=ad,DC=cooklab,DC=com" -Members `
  "CN=Michael Cook,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Olivia Lajoie,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Ramon Jackson,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Agnes Chan,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com"

Add-ADGroupMember -Identity "CN=3rd Line Support,OU=IT,DC=ad,DC=cooklab,DC=com" -Members `
  "CN=Michael Cook,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=Olivia Lajoie,OU=Users,OU=IT,DC=ad,DC=cooklab,DC=com"

Add-ADGroupMember -Identity "CN=Service Desk Techs,OU=IT,DC=ad,DC=cooklab,DC=com" -Members `
  "CN=1st Line Support,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=2nd Line Support,OU=IT,DC=ad,DC=cooklab,DC=com",
  "CN=3rd Line Support,OU=IT,DC=ad,DC=cooklab,DC=com"