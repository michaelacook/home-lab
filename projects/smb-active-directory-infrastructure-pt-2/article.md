# Small-Medium Business Active Directory Infrastructure Part 2: Configuring Hybrid Identity

## Introduction

In the [previous article](<../smb-active-directory-infrastructure-pt-1/article.md>) I detailed the initial setup of the network, servers and directory structure of this project. In this article I am going to walk the reader through the addition of a custom UPN suffix and the configuration of hybrid identity using Azure Cloud Connect.

## Adding a New UPN Suffix

An Active Directory domain is typically a private sub-domain that is not Internet-reachable. In other words, your internal corporate domain cannot be resolved using name servers publicly available on the Internet. You host DNS servers yourself that are authoritative for your domain, and these would almost never be exposed publicly. 

However, if you want to provision your users into the cloud so that they can be assigned access on cloud-based applications, you will likely want those users to have a UPN suffix for a public domain that you own. I own the domain `mikecooklab.com` and I have it configured and added as the primary domain for my Azure default Entra ID tenant.

![Custom domains in Azure](<images/azure-custom-domains.PNG>)

When I provision users in my domain into my Entra ID tenant, I want them to use my own domain as their UPN suffix and not the default `*.onmicrosoft.com` UPN suffix that comes with an Entra ID tenant. But if the users have a private, non-publicly reachable domain like `ad.cooklab.com` as their UPN suffix then they will be automatically given the default UPN suffix, since `ad.cooklab.com` is not a verified domain in the tenant. It is possible to fix this at a later time, but there isn't a good reason not to do it prior to the initial sync. So I added `mikecooklab.com` as an additional UPN suffix from Active Directory Domains and Trusts and then ran a script I had pre-written to change the primary UPN suffix for all users in my domain.

### Adding additional UPN suffixes

![Adding a UPN Suffix in AD](<images/adding-new-upn-suffix.PNG>)

### Script to update all UPN suffixes

```ps
$Users = Get-ADUser -Filter {UserPrincipalName -like '*ad.cooklab.com'} -Properties UserPrincipalName

ForEach ($u in $Users) {
    $newUPN = $u.UserPrincipalName.Replace("ad.cooklab.com", "mikecooklab.com")
    $u | Set-ADUser -UserPrincipalName $newUPN
}
```
### UPN suffixes updated

![Users with new UPN Suffix](<images/upns-updated.PNG>)

Users can still authenticate with the domain using their first UPN suffix; but having a new UPN suffix that matches the default for my Entra ID tenant makes their user principals more professional.

## Installing and Configuring Microsoft Entra Connect Sync

With UPN suffixes in place, I proceeded with creating a new server instance to run Microsoft Entra Connect Sync. Entra Connect Sync can be run on a domain controller, but Microsoft recommends installing it on a separate member server instead. I created a new virtual machine and gave it a hostname of `LON-DIRSYNC` and a static IP of `10.0.254.4`. I then logged into my Azure tenant and downloaded the Entra Connect setup executable.

Installation and configuration is fairly straight-forward and involves providing credentials for a Global Administrator in your target Entra ID tenant, Enterprise Admin credentials for your domain, and verifying the source and target domain and UPN suffix security principals will use. For this lab accepting default configuration options was sufficient.

![Entra Connect Sync Installation 1](<images/entra-connect-install-1.PNG>)
![Entra Connect Sync Installation 2](<images/entra-connect-install-2.PNG>)
![Entra Connect Sync Installation 3](<images/entra-connect-install-3.PNG>)
![Entra Connect Sync Installation 4](<images/entra-connect-install-4.PNG>)
![Entra Connect Sync Installation 5](<images/entra-connect-install-5.PNG>)

Finally, I verified that the sync was successful using the Sychronization Service Manager and in the Azure portal.

![Sychronization Service Manager successful sync](<images/synchronization-service-manager-success.PNG>)
![Users synced to Entra ID](<images/users-synced.PNG>)
![Groups synced to Entra ID](<images/groups-synced.PNG>)

## Next Steps