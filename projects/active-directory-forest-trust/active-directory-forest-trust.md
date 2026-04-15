# Configuring an Active Directory Forest Trust

This article details the steps taken and lessons learned while configuring a two-way trust between two Active Directory forests separated by a simulated WAN link. Complex Active Directory topologies are less common today with the advent of hybrid cloud technologies. Nevertheless, I still felt there is value in gaining familiarity with these technologies as they do continue to be used in the enterpise. Moreover, understanding modern cloud solutions is enhanced by understanding the types of problems from the past that they solve.

## Topology

This project was build using the following resources:
- Windows Server 2022 Standard Evaluation
- Cisco vIOS router
- Unmanaged switch

The main task of this lab was to establish a successful two-way trust between the two forests such that resources should be shared. I decided to keep the topology as simple as possible while injecting a degree of realism. To this end, I set up two networks on with /24 subnets separated by one hop to my home LAN, and configured a point-to-point connection and a GRE tunnel between them to simulate a direct tunnel over a WAN link.

![Topology](<images/ad-forest-trust-topology.png>)

## Router Configuration

Because this lab is focused on the Active Directory topology, I will not go into detail on the networking configuration. All router startup configurations can be found in [config](<config/>). Each router was given a base configuration, configured to perform network address translation for external connectivity to my home LAN and the Internet, and a GRE tunnel was configured allowing connectivity between the private networks `10.0.1.0/24` and `10.0.2.0/24` over a point-to-point connection.

The following tables shows all networks configured on both routers

#### COOKLAB-R1

|Interface|IP|Prefix|Purpose|
|-|-|-|-|
|G0/0|10.0.1.1|/24|LAN, inside NAT|
|G0/1|203.0.113.1|30|Point-to-point|
|G0/2|DHCP|/24|Outside NAT|
|Tunnel0|10.0.3.253|/30|GRE tunnel|

#### MIKELAB-R1

|Interface|IP|Prefix|Purpose|
|-|-|-|-|
|G0/0|10.0.2.1|/24|LAN, inside NAT|
|G0/1|203.0.113.2|/30|Point-to-point|
|G0/2|DHCP|/24|Outside NAT|
|Tunnel0|10.0.3.254|/30|GRE tunnel|

## Initial Server Configuration

Initial server configuration involved ensuring correct time configuration, running all updates, configuring hostnames and static IP addresses, then installing Active Directory Domain Services on each server.

## Active Directory Configuration

I installed Active Directory Domain Services on each Windows Server, and created a new forest domain and promoted each to domain controller. In the 10.0.1.0/24 subnet I created the `ad.cooklab.com` domain and in the 10.0.2.0/24 subnet I created the `corp.mikelab.com` domain.

#### `DC1.ad.cooklab.com` Server Manager
![DC1.ad.cooklab.com](<images/dc1-cooklab-server-manager.png>)

#### `DC01.ad.mikelab.com` Server Manager
![DC01.corp.mikelab.com](<images/dc01-mikelab-server-manager.png>)

### DNS

I wanted the two domain controllers to be able to have web reachability and to use my Pihole DNS server, so I configured forwarders for both. Web reachability doesn't depend on having forwarders in place, but without a forwarder the domain controller will use it's own DNS root hints to recursively resolve names it doesn't have records for.

Importantly, a prerequisite for configuring a two-way forest trust is two-way name resolution between each forest root domain. `DC1.ad.cooklab.com` must be able to resolve names for `corp.mikelab.com` and vice versa. This can be achieved with the creation of a stub zone for each domain, or with conditional forwarders. Stub zones are more maintainable as they will always have up to date records even when IP addresses change. Conditional forwarders are statically set and must be updated manually. To begin, I set up conditional forwarders, but intend to replace these with stub zones.
<!-- Not sure these images are really needed, doesn't contribute much to the lab write-up -->
<!-- ![DC1.ad.cooklab.com DNS Forwarder](<images/dc1-cooklab-dns-forwarder.png>) -->
<!-- ![DC01.corp.mikelab.com DNS Forwarder](<images/dc01-mikelab-dns-forwarder.png>) -->

#### Conditional forwarder for `corp.mikelab.com` on DC1
![Conditional forwarder for corp.mikelab.com on DC1](<images/dc1-cooklab-conditional-forwarder.png>)

#### Conditional forwarder for `ad.cooklab.com` on DC01
![Conditional forwarder for ad.cooklab.com on DC01](<images/dc01-mikelab-conditional-forwarder.png>)

## Configuring the Forest Trust

With two-way name resolution in place, configuring the forest trusts involves opening Active Directory Domains and Trusts, right-clicking the domain, selecting **Properties**>**Trusts** and selecting **New Trust...** to start the configuration wizard.

You then proceed through the wizard, which involves specifying the forest or domain with which you intend to create a trust relationship, selecting the directionality of the trust relationship, specifying whether to create both sides of the trust relationship in a two-way trust, providing enterprise admin credentials for the other side of the trust, and selecting the scope of the trust. I opted to set up both sides of the trust from the wizard on `dc1.ad.cooklab.com` and opted to allow forest-wide authentication rather than restricting the scope of authentication only to specific domains or resources, as there is only one domain in each forest. The following screenshots demonstrate the configuration wizard process.

![New Trust Wizard](<images/ad-forest-trust-wizard-1.PNG>)
![New Trust Wizard](<images/ad-forest-trust-wizard-2.PNG>)
![New Trust Wizard](<images/ad-forest-trust-wizard-4.PNG>)
![New Trust Wizard](<images/ad-forest-trust-wizard-5.PNG>)
![New Trust Wizard](<images/ad-forest-trust-wizard-6.PNG>)
![New Trust Wizard](<images/ad-forest-trust-wizard-7.PNG>)
![New Trust Wizard](<images/ad-forest-trust-wizard-8.PNG>)
![New Trust Wizard](<images/ad-forest-trust-wizard-9.PNG>)

The trust relationship was configured successfully and appears in AD Domains and Trusts on both `DC1.ad.cooklab.com` and `DC01.corp.mikelab.com`.

![New Trust Wizard](<images/ad-forest-trust-dc1-complete.PNG>)
![New Trust Wizard](<images/ad-forest-trust-dc01-complete.PNG>)

## Testing the Forest Trust

I wanted to test the health of the trust and ensure that users in each forest can be added to groups on both side of the trust relationship. First, I tested the trust on both sides with `nltest`:

#### `dc1.ad.cooklab.com`
![nltest on DC1.ad.cooklab.com](<images/nltest-dc1.png>)

#### `dc01.corp.mikelab.com`
![nltest on DC01.corp.mikelab.com](<images/dc01-nltest.png>)

Next, I added the following users:

|Display Name|UPN|
|-|-|
|Tim Berners-Lee|tim.berners-lee@ad.cooklab.com|
|Bob Metcalfe|bob.metcalfe@ad.cooklab.com|
|David Boggs|david.boggs@corp.mikelab.com|
|Donald Davies|donald.davies@corp.mikelab.com|

And the following domain-local groups:

|Name|Domain|
|-|-|
|Toronto Users - External|AD.COOKLAB|
|London Users - External|CORP.MIKELAB|

I was then able to add David Boggs and Donald Davies to the **Toronto Users - External** group in the `ad.cooklab.com` domain, and Tim Berners-Lee and Bob Metcalfe to the **London Users - External** Group in the `corp.mikelab.com` domain.

![DC1 External Group Membership](<images/dc1-cooklab-external-group-membership.png>)
![DC01 External Group Membership](<images/dc01-mikelab-external-group-membership.png>)

The reason domain-local groups were used is that as per [Microsoft's documentation](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-groups#how-active-directory-security-groups-work), domain-local groups are the only group type that allows the addition of users and groups from trusted external domains. Domain-local groups are typically granted permissions directly on resources (only in the domain they are created), and users or groups from any domain in the forest or trusted domain may be added as members. From here, these groups could be granted permissions, allowing cross-organizational file and resource sharing.

## Configuring a Stub DNS Zone

I previously configured conditional forwarders for name resolution between the two forest root domains. Stub zones are a more maintainable approach, allowing for dynamic update of DNS records.

## Mistakes and Lessons Learned

I made a few mistakes along the way with this project and had to partially rebuild a couple times.

First lesson: **NetBIOS names must be unique**. When I first set out to begin this project, I initially created both forests as a subdomain of `ad.`. Thus the fully qualified domain names for each were `ad.cooklab.com` and `ad.mikelab.com` and this prevented me from proceeding through the new trust wizard. My research found that the NetBIOS name of each domain or forest must be unique. With both forests being subdomains of `ad.`, both would have the NetBIOS name AD. 

Second lesson: **Hostnames must be unique**. When I first promoted my domain controllers, I gave them each the hostname of `DC1`. This resulted in the error `ERROR_NO_LOGON_SERVERS` after creating the trust. My research suggested that hostname conflicts will cause issues with authentication. I changed the hostname of `DC1.corp.mikelab.com` to `DC01.corp.mikelab.com` and this resolved the error.

The issue of overlapping NetBIOS names made sense to me, but I was confused by the issue related to hostnames. I would have that that as long as the FQDN is unique, authentication could proceed. In practice this would rarely be an issue, as hosts are typically named by combination of location, service, etc. Were I do re-build this project I would probably name one host `LON-DC1.ad.cooklab.com` and the other `TO-DC1.corp.mikelab.com`

## Conclusion

In this article I outlined the steps I took to configure a two-way Active Directory forest trust. Forest trusts are some times done to support mergers or acquisitions, but complex Active Directory topologies are less necessary today with the use of technologies like SharePoint Online and other cloud technologies that allow easy resource sharing without WAN connections, VPNs or trusts. Nevertheless, because this technology may continue to be used for some time in the enterprise, it was a worthwhile exercise and taught me more about authentication and the subtlte differences between types of security groups.