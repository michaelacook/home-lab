Import-Module ActiveDirectory

$BaseDN = "DC=ad,DC=cooklab,DC=com"

$TopLevelOUs = @{
    "IT"        = @()  
    "Employees" = @("Sales", "Marketing", "Finance", "HR", "Engineering")
}

New-ADOrganizationalUnit -Name "IT" -Path $BaseDN
foreach ($SubOU in @("Users", "Computers")) {
    New-ADOrganizationalUnit -Name $SubOU -Path "OU=IT,$BaseDN"
}

New-ADOrganizationalUnit -Name "Employees" -Path $BaseDN
foreach ($Dept in $TopLevelOUs["Employees"]) {
    New-ADOrganizationalUnit -Name $Dept -Path "OU=Employees,$BaseDN"
    foreach ($SubOU in @("Users", "Computers")) {
        New-ADOrganizationalUnit -Name $SubOU -Path "OU=$Dept,OU=Employees,$BaseDN"
    }
}