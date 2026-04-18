Import-Module ActiveDirectory

New-ADGroup -Name "Engineering Dept" -GroupCategory Security -GroupScope Global -Path "OU=Engineering,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADGroup -Name "Sales Dept" -GroupCategory Security -GroupScope Global -Path "OU=Sales,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADGroup -Name "Marketing Dept" -GroupCategory Security -GroupScope Global -Path "OU=Marketing,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADGroup -Name "Finance Dept" -GroupCategory Security -GroupScope Global -Path "OU=Finance,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADGroup -Name "HR Dept" -GroupCategory Security -GroupScope Global -Path "OU=HR,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADGroup -Name "IT Dept" -GroupCategory Security -GroupScope Global -Path "OU=IT,DC=ad,DC=cooklab,DC=com"