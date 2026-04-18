Import-Module ActiveDirectory

New-ADOrganizationalUnit -Name "IT"
New-ADOrganizationalUnit -Name "Users" -Path "OU=IT,DC=ad,DC=cooklab,DC=com"
New-ADOrganizationalUnit -Name "Computers" -Path "OU=IT,DC=ad,DC=cooklab,DC=com"

New-ADOrganizationalUnit -Name "Employees"

New-ADOrganizationalUnit -Name "Sales" -Path "OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADOrganizationalUnit -Name "Users" -Path "OU=Sales,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADOrganizationalUnit -Name "Computers" -Path "OU=Sales,OU=Employees,DC=ad,DC=cooklab,DC=com"

New-ADOrganizationalUnit -Name "Marketing" -Path "OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADOrganizationalUnit -Name "Users" -Path "OU=Marketing,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADOrganizationalUnit -Name "Computers" -Path "OU=Marketing,OU=Employees,DC=ad,DC=cooklab,DC=com"

New-ADOrganizationalUnit -Name "Finance" -Path "OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADOrganizationalUnit -Name "Users" -Path "OU=Finance,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADOrganizationalUnit -Name "Computers" -Path "OU=Finance,OU=Employees,DC=ad,DC=cooklab,DC=com"

New-ADOrganizationalUnit -Name "HR" -Path "OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADOrganizationalUnit -Name "Users" -Path "OU=HR,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADOrganizationalUnit -Name "Computers" -Path "OU=HR,OU=Employees,DC=ad,DC=cooklab,DC=com"

New-ADOrganizationalUnit -Name "Engineering" -Path "OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADOrganizationalUnit -Name "Users" -Path "OU=Engineering,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADOrganizationalUnit -Name "Computers" -Path "OU=Engineering,OU=Employees,DC=ad,DC=cooklab,DC=com"