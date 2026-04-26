Import-Module ActiveDirectory

$BaseDN    = "DC=ad,DC=cooklab,DC=com"
$ITUsersOU = "OU=Users,OU=IT,$BaseDN"
$ITOU      = "OU=IT,$BaseDN"
$PrivOU    = "OU=Privileged Accounts,OU=Users,OU=IT,$BaseDN"

### CREATE IT GROUPS

$ITGroups = @("Service Desk Techs", "1st Line Support", "2nd Line Support", "3rd Line Support")

foreach ($Group in $ITGroups) {
    New-ADGroup -GroupCategory Security -GroupScope Global -Name $Group -Path $ITOU
}

### CREATE OUs

New-ADOrganizationalUnit -Name "Privileged Accounts" -Path $ITUsersOU

### CREATE IT DEPT USERS

# Tiers: list which support tiers each user belongs to (mirrored to their privileged account)
$ITUsers = @(
    @{ Name = "Jen Barber";    Title = "Director of IT";            Manager = $null;                         Tiers = @()        },
    @{ Name = "Michael Cook";  Title = "Network Administrator";     Manager = "CN=Jen Barber,$ITUsersOU";    Tiers = @(1, 2, 3) },
    @{ Name = "Olivia Lajoie"; Title = "System Administrator";      Manager = "CN=Jen Barber,$ITUsersOU";    Tiers = @(1, 2, 3) },
    @{ Name = "Ramon Jackson"; Title = "Service Desk Analyst II";   Manager = "CN=Olivia Lajoie,$ITUsersOU"; Tiers = @(1, 2)    },
    @{ Name = "Jamie Perkins"; Title = "Service Desk Analyst I";    Manager = "CN=Olivia Lajoie,$ITUsersOU"; Tiers = @(1)       },
    @{ Name = "Agnes Chan";    Title = "Infrastructure Technician"; Manager = "CN=Michael Cook,$ITUsersOU";  Tiers = @(1, 2)    }
)

function New-LabADUser {
    param(
        [string]$Name,
        [string]$DisplayName,
        [string]$Sam,
        [string]$UPN,
        [string]$Title,
        [string]$Department,
        [string]$Path,
        [string]$Manager
    )

    $Params = @{
        Name                  = $Name
        DisplayName           = $DisplayName
        Department            = $Department
        Path                  = $Path
        Title                 = $Title
        Description           = $Title
        UserPrincipalName     = $UPN
        SamAccountName        = $Sam
        PasswordNeverExpires  = $false
        ChangePasswordAtLogon = $true
        AccountPassword       = $null
        Enabled               = $false
    }

    if ($Manager) { $Params.Manager = $Manager }

    New-ADUser @Params
}

foreach ($User in $ITUsers) {
    $Sam = $User.Name.ToLower().Replace(" ", ".")
    $UPN = "$Sam@ad.cooklab.com"

    # Regular account
    New-LabADUser `
        -Name        $User.Name `
        -DisplayName $User.Name `
        -Sam         $Sam `
        -UPN         $UPN `
        -Title       $User.Title `
        -Department  "IT" `
        -Path        $ITUsersOU `
        -Manager     $User.Manager

    # Privileged account
    New-LabADUser `
        -Name        "$($User.Name) (privileged)" `
        -DisplayName "$($User.Name) (privileged)" `
        -Sam         "$Sam.p" `
        -UPN         "$Sam.p@ad.cooklab.com" `
        -Title       $User.Title `
        -Department  "IT" `
        -Path        $PrivOU `
        -Manager     $null
}

### ADD GROUP MEMBERSHIPS

$CNUser = { param($Name) "CN=$Name,$ITUsersOU" }
$CNPriv = { param($Name) "CN=$Name,$PrivOU"    }

# All regular and privileged accounts into IT Dept
$ITDeptMembers = $ITUsers | ForEach-Object {
    & $CNUser $_.Name
    & $CNPriv "$($_.Name) (privileged)"
}
Add-ADGroupMember -Identity "CN=IT Dept,$ITOU" -Members $ITDeptMembers

# Tier groups: privileged accounts only, mirrored from $ITUsers Tiers property
$TierGroups = @{
    1 = "CN=1st Line Support,$ITOU"
    2 = "CN=2nd Line Support,$ITOU"
    3 = "CN=3rd Line Support,$ITOU"
}

foreach ($Tier in $TierGroups.Keys) {
    $Members = $ITUsers | Where-Object { $_.Tiers -contains $Tier } | ForEach-Object {
        & $CNPriv "$($_.Name) (privileged)"
    }
    if ($Members) {
        Add-ADGroupMember -Identity $TierGroups[$Tier] -Members $Members
    }
}

# Service Desk Techs remains a group-of-groups
Add-ADGroupMember -Identity "CN=Service Desk Techs,$ITOU" -Members @(
    "CN=1st Line Support,$ITOU",
    "CN=2nd Line Support,$ITOU",
    "CN=3rd Line Support,$ITOU"
)