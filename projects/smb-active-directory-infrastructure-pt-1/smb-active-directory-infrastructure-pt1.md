# Small-Medium Business Active Directory Infrastructure Part 1: Initial Setup

## Introduction

In this series of write-ups I am going to detail the set up and configuration of a medium-sized corporate office domain `ad.cooklab.com` from initial DC promotion, configuration of network services, file sharing, common-sense group policies for basic security and standardization, to the creation of hybrid identity, remote access VPN, and backup and recovery of critical services and resources.

I will be creating a simple perimeter network with a Pfsense firewall for isolation and to demonstrate the configuration of a remote access VPN, but because the focus of this lab project is on the configuration of essential IT services I will be leaving the network unsegmented. It is possible to create a router-on-a-stick topology with Pfsense, but I decided against doing this here. In an [older project](<../smb-active-directory-infrastructure-segmented/active-directory-infrastructure-segmented.md>) I configured a ROAS topology with Pfsense and found it added unnecessary complexity for a project that was otherwise focused on application layer technologies.

In this first write-up I will go through initial forest creation, the promotion of domain controllers, the creation of the organizational unit structure, and the creation of users. Most of these tasks will be done with scripts I have pre-written.

## Table of Contents
- Basic network setup
- Server configuration and forest creation
- Creating users, groups and organizational units
- Next steps

## Basic Network Setup

This project will not focus on network design or configuration. However, we do need to isolate the lab network from my home LAN and create a sensible IP addressing scheme. In Proxmox I have created an Open Virtual Switch (OVS) bridge named vmbr2 for the lab network and connected it and my main Linux bridge vmbr0 to a new Pfsense CE 2.7.2 virtual machine. At the same time, I have created a new Windows Server 2022 Datacenter Evaluation virtual machine from which I will do initial firewall configuration via the Pfsense web configurator. This virtual machine will also be the first domain controller in the forest. Setting up the Windows Server 2022 virtual machine is fast, as I have previously created a VM, installed all updates, sysprepped the machine and converted it to a virtual machine template.

I gave the Pfsense virtual machine two virtual CPUs, 2048 MB of RAM and 20 GB of storage space. I have found that for lab environments that do not produce a lot of outbound traffic this sizing works well. After running through the Pfsense installation, I opened up the web configurator at the default IP of `192.168.1.1` and logged in with the default username and password (admin, pfsense) and went through the initial firewall configuration.

![Pfsense Webconfigurator Login Page](<images/pfsense-login-page.PNG>)

On the first page of the configuration wizard, I gave the firewall a hostname of `cooklab-fw1` and a domain of `cooklab.internal` so that the domain doesn't interfere with Windows Server DNS. I set the primary DNS server temporarily to Cloudflare's DNS `1.1.1.1`, though this will be changed later when we add the primary and secondary domain controllers.

![Pfsense General Information](<images/pfsense-config-1.PNG>)

I left the default time server and set Canada/Eastern as the timezone, and then proceeded to WAN interface configuration and accepted all defaults, including the rules that restrict RFC 1918 and bogon (non-RFC 1918 but otherwise reserved) networks from accessing the WAN interface. I then set the LAN interface address to `10.0.254.1` with a /24 subnet mask. I chose `10.0.254.0/24` as the LAN network because later on we will be setting up a remote access VPN on the firewall. In the real world, it is important not to use the default `192.168.1.0/24` network as this is incredibly common on home routers. If a remote employee whose home network uses that network connects in via VPN, they will have difficulty reaching resources on the corporate LAN due to IP conflicts.

![Pfsense LAN Configuration](<images/pfsense-config-2.PNG>)

Finally, I set a new administrator password completed the configuration wizard. I then performed an IP release and renew, then verified the web configurator can be reached at the new IP address.

![IP Release and Renew](<images/ipconfig-release-renew.PNG>)
![Webconfigurator at New IP](<images/webconfigurator-new-ip.PNG>)

Basic firewall configuration is complete. Cooklab-fw1 is configured out of the box to do network address translation and will allow all outbound traffic, so for the moment there are no firewall rules to create.

![NAT Out of the Box](<images/pfsense-automatic-nat.PNG>)

However, despite having connectivity out to my home LAN and the Internet, I didn't have name resolution. After some investigation I found that DNSSEC was enabled by default and this was causing name resolution failures. Because the firewall was in resolver mode, any recursive queries would ultimately fail if any recursive server in the chain failed DNSSEC. I decided instead to turn off resolver mode and enable forward mode. This means the firewall will forward all queries to the primary DNS server I configured during initial setup. Ultimately, DNS and DHCP will be configured on Windows Server and the firewall will no longer be used to hand out IP addresses or perform name resolution.

## Server Configuration and Forest Creation

Up until this point I have been doing the basic firewall configuration from a newly created Windows Server 2022 Datacenter Evaluation machine with 8 GB of RAM, 4 virtual CPUs and 40 GB of storage. The storage capacity would not be anywhere close to sufficient in a real-world setup, and I will probably increase the size of the disk and extend the C: volume at a later time. Because initial configuration wasn't complete, I ran all outstanding updates, ensured the timezone was correct, set a static IP of `10.0.254.2`, and a hostname of `DC1`.

![Basic Server Config on DC1](<images/basic-server-config-dc1.PNG>)

After completing basic configuration I installed Active Directory Domain Services with PowerShell and triggered a reboot after successful installation.

![AD Installation Complete](<images/AD-installed-dc1.PNG>)

After rebooting, I downloaded a forest installation script I had previously created to configure the domain `ad.cooklab.com` and ran the script, which can be viewed in full [here](<scripts/CooklabADDSDeployment-DC1.ps1>). I provided a Directory Services Restore Mode password, then the script completed and the machine rebooted.

![New Domain Controller](<images/dc1-configured.PNG>)

With the promotion of the first domain controller, it's now time to create the secondary domain controller. Having at least two domain controllers in a corporate office network is important for load balancing and availability of network resources. I created a second Windows Server instance, this time using Windows Server 2022 Datacenter Core Evaluation and 8 GB of RAM, 4 virtual CPUs and 100 GB of storage space.

Most basic configuration tasks on Server Core can be done through the SConfig utility, a text-based menu-driven environment. I installed all available updates, set the timezone, a static IP of `10.0.254.3`, set the DNS server to `DC1`,and domain-joined the server with a hostname of `DC2`. I then added `DC2` for remote management in Server Manager on `DC1`.

![DC2 added to Server Manager](<images/DC2-added.PNG>)

I then went back to `DC2` and downloaded my domain controller installation script from GitHub and installed Active Directory Domain Services.

![Active Directory installed on DC2](<images/dc2-adds-installed.PNG>)

Finally, I ran the downloaded script to promote `DC2` to domain controller for `ad.cooklab.com`.

![Promoting DC2 to DC](<images/DC2-running-promotion-script.PNG>)

`DC2` is now visible in the Domain Controllers built-in Domain Controllers OU.

![DC2 successfully promoted](<images/DC2-successfully-promoted.PNG>)

## Creating Users, Groups and Organizational Units

With both domain controllers promoted I moved on to creating the organizational unit structure, along with groups and users. First I downloaded a script I had pre-written to create the organizational unit structure. Given that the script is short I will show it here, but it can also be viewed [here](<scripts/CreateCooklabOUStructure-Refactored.ps1>).

```ps
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
```

The script produces an OU structure that looks like the following representation:

```
DC=ad,DC=cooklab,DC=com
├── OU=IT
│   ├── OU=Users
│   └── OU=Computers
└── OU=Employees
    ├── OU=Sales
    │   ├── OU=Users
    │   └── OU=Computers
    ├── OU=Marketing
    │   ├── OU=Users
    │   └── OU=Computers
    ├── OU=Finance
    │   ├── OU=Users
    │   └── OU=Computers
    ├── OU=HR
    │   ├── OU=Users
    │   └── OU=Computers
    └── OU=Engineering
        ├── OU=Users
        └── OU=Computers
```

I downloaded the script from GitHub, temporarily set the PowerShell execution policy to unrestricted and ran the script.

![Running OU creation script](<images/dc1-create-ou-structure.PNG>)
![OU structure created](<images/OU-structure-created.PNG>)

I also verified that changes successfully replicated to `DC2`.

![OU structure on DC2](<images/OUs-on-dc2.PNG>)

I used this OU structure because it's similar to what we use in the organization where I work. The reason for separating IT from the rest of the company is to apply a special set of group policy objects to IT while standardizing the rest of the organization. However, while working on this project I came to the conclusion that this structure could be improved by moving the IT department under the Employees OU and therefore subjecting it to the same set of standard policies that affect the entire organization, and create another OU where privileged accounts and computers live, i.e., privileged users belonging to special groups and virtual machines for admin work accessed via RDP. Completely separating privileged access from day to day usage accounts is a best practice and this could be reflected in the OU structure of the domain.

I then downloaded and ran another [script](<scripts/CreateDepartmentGroups.ps1>) I had previously written to create departmental groups for all OUs under Employees, which will serve later as a way to provide departmental file shares.

```ps
Import-Module ActiveDirectory

New-ADGroup -Name "Engineering Dept" -GroupCategory Security -GroupScope Global -Path "OU=Engineering,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADGroup -Name "Sales Dept" -GroupCategory Security -GroupScope Global -Path "OU=Sales,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADGroup -Name "Marketing Dept" -GroupCategory Security -GroupScope Global -Path "OU=Marketing,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADGroup -Name "Finance Dept" -GroupCategory Security -GroupScope Global -Path "OU=Finance,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADGroup -Name "HR Dept" -GroupCategory Security -GroupScope Global -Path "OU=HR,OU=Employees,DC=ad,DC=cooklab,DC=com"
New-ADGroup -Name "IT Dept" -GroupCategory Security -GroupScope Global -Path "OU=IT,DC=ad,DC=cooklab,DC=com"
```

Next I downloaded and ran a script I had pre-written to create the IT Department OU with a team of IT users and their privileged administrator user principals. The script can be viewed [here](<scripts/CreateITUsersAndGroups-Refactored.ps1>). The script creates an OU called IT, with Users and Computers sub-OUs, and an OU called Privileged Accounts within Users. This OU contains accounts that follow the format firstname.lastname.p that IT admins can use for administrative work separate from day to day end user activities. The script also creates groups for three support tiers, an IT Dept group and a Service Desk Techs group for the support team.

![IT Users OU](<images/it-ou-users.PNG>)
![IT Dept Groups](<images/it-dept-groups.PNG>)
![Privileged Accounts](<images/p-accounts.PNG>)

Having separate privileged accounts is a useful security tactic that separates day to day accounts for routine tasks like email and collaboration from accounts used for administrative work. For instance, Network Administrator Michael Cook is the primary network admin and needs membership in the Enterprise Admins group. Instead of adding his regular employee security principal to a group that has such broad access, only his privileged account is added to the Enterprise Admins group. If his day to day credentials were to be compromised, the attacker would only have non-admin access on the domain. Privileged accounts are never used to login to Windows and aren't given a Microsoft 365 license as their purpose is not for email and collaboration.

Finally, I created test users for each department, and added them to the correct OU and departmental security group. I downloaded a script I had previously written and a CSV file with user data. The data can be viewed [here](<data/Users.csv>).

```ps
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
```
![Test Users](<images/users-1.PNG>)

## Next Steps

In this write-up I demonstrated initial set up of the network, basic server configuration, the creation of the Active Directory forest, and the creation of users and the domain's directory structure. In the next installment I will demonstrate the addition of an additional UPN suffix for a domain I own and update all users with the new suffix, then configure hybrid identity with Entra Cloud Connect.