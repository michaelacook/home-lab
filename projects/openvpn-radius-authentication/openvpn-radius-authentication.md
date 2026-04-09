# Configuring OpenVPN with RADIUS Authentication

November 23, 2025

This post will detail the steps I took to set up a simple collapsed-core network with an Active Directory domain and Network Policy Server for RADIUS authentication for OpenVPN. Configuring a remote-access VPN is a big task and there are many ways to do it with a large array of configuration options. I am far from an expert in any of them. This article demonstrates my attempt to learn how the various components work together to provide connectivity to clients.

## Topology

This project was built in GNS3 running as a guest in Proxmox. The following devices were used:
- Windows Server 2022
- Pfsense Community Edition
- Multilayer switch
- VPC, TinyCore Linux and Windows 10 guests for testing

![Topology](<images/topology 1.png>)

The WAN interface of the firewall connected out to my home LAN via a cloud node in GNS3. A Windows 10 client running in Proxmox connected to the bridged adapter was used to test the VPN.

The switch provided layer 3 forwarding between VLANs and a static default route sending all unknown traffic through the firewall. The Windows Server node provided DNS and DHCP and the firewall appliance was configured for Network Address Translation to provide reachability to external networks and the Internet.

A /29 perimeter network between the firewall and switch was created for the purposes of initial configuration of the firewall. I needed a way to connect a device with a browser directly to a subnet on the LAN interface in order to go through the setup wizard and create rules for management access on the OPT1 interface. For this I used the ready-made Firefox node with a TinyCore Linux base provided by GNS3. Afterward the firewall's OPT1 interface was connected to the management VLAN on the switch.

### VLANs

| ID  | Name           | Subnet           | Gateway       |
| --- | -------------- | ---------------- | ------------- |
| 99  | Management     | 192.168.99.0/24  | 192.168.99.1  |
| 100 | Users          | 192.168.100.0/24 | 192.168.100.1 |
| 200 | Infrastructure | 192.168.200.0/24 | 192.168.200.1 |
| 789 | Unused         | -                | -             |

### IP Addressing

All infrastructure devices were assigned a static IP. DHCP on Windows Server was used for the Users VLAN.

| Device           | Interface          | Address       | CIDR | Role                           |
| ---------------- | ------------------ | ------------- | ---- | ------------------------------ |
| DC01             | NIC1               | 192.168.200.2 | /24  | Infrastructure                 |
| DC01             | NIC2               | 192.168.99.3  | /24  | Management                     |
| MLSW1            | GigabitEthernet3/3 | 192.168.1.2   | /29  | Routed port to FRWL1           |
| MLSW1            | Vlan 99            | 192.168.99.1  | /24  | Management                     |
| FRWL1            | em0                | 192.168.1.1   | /29  | LAN                            |
| FRWL1            | em1                | 192.168.99.2  | /24  | Management                     |
| FRWL1            | em2                | 192.168.127.7 | /24  | WAN                            |
| PC1              | NIC1               | DHCP          | /24  | Users VLAN                     |
| Firefox-TinyCore | NIC1               | DHCP          | /24  | Linux guest with a web browser |

------

## Active Directory

The Active Directory Domain Services and DNS roles were installed and a new forest was created with the domain cooklab.local. The server was promoted to a domain controller and a DNS forwarder was created for the recursive name server I host on my home LAN in Pihole. Additionally, I created a global security group called OpenVPN Users and a test user name Robert Metcalfe. In the DNS manager console I created an A record for the firewall appliance. These will be needed later when configuring RADIUS.

![ADDS View](images/ADDS_view.png)

![DNS View](images/DNS_view.png)

![DNS Forwarder](images/DNS_forwarder.png)

## DHCP

The DHCP role was installed on the domain controller, registered in Active Directory and a new scope was created corresponding to the Users VLAN. I set the lease time to 1 hour and provided the standard options. A DHCP relay agent was configured on the virtual interface for VLAN 100 pointing to the domain controller's IP.

![DHCP View](images/DHCP_view.png)

![DHCP Client](images/DHCP_client.png)


-----

## Pfsense Web Configurator Console Access

I wanted to be able to access the firewall's web configurator (this is what Pfsense calls the web-based management console) only via the management interface for security reasons. I therefore created rules on the OPT1 interface allowing HTTP/S as well as SSH and VNC traffic from the management VLAN before removing the anti-lockout rule on the LAN interface. This was a mistake and resulted in being immediately locked out. I had to access the console of the firewall and reset the password, which allowed me to access the web configurator on the LAN interface again. I was unable to find a way to make the web configurator available over the management interface, so instead I added rules on the LAN interface allowing web traffic from the management VLAN and blocking web traffic from the Users VLAN. This achieved the correct result. This also made the management interface I added to the firewall unnecessary in this lab environment. I decided to leave it regardless because a bare metal firewall would have a management interface connected into a management VLAN. I tested to ensure VLAN 100 devices could reach the Web without being able to reach the web configurator.

![FRWL LAN Rules](<images/FRWL_LAN rules.png>)

![Web Reachability from VLAN 100](<images/web reachability from vlan 100.png>)

## Network Address Translation

Before going further with VPN configuration, I wanted to set up NAT so that devices could reach external networks and the Internet. Pfsense will only translate traffic for networks that it knows about, so I needed to create a gateway to be used in static routes for the Users and Infrastructure networks. After creating a gateway, I was able to create static routes.

![NAT Static Routes](<images/Pasted image 20251124203152.png>)

![NAT Routes](<images/Pasted image 20251124203238.png>)

Initially, I thought that outbound rules would need to be manually created for translation, but Pfsense will add translation rules for networks it has static routes to automatically. Note that there is no static route to the Management subnet, but it is still covered by the automatic outbound translation rules because it is directly connected on the OPT1 interface.

![NAT Outbound Rules](<images/Pasted image 20251124203816.png>)

With static routes and NAT rules in place, devices can reach my home LAN and the Internet.

![NAT Connectivity Test](<images/Pasted image 20251124204139.png>)


------

## OpenVPN Configuration

In this section I will outline the steps I took to configure OpenVPN with RADIUS authentication. First, configuration of Network Policy Server, then the creation of a certificate authority and certificate, the configuration of a VPN server, then the export of configuration files and client installation.

### Network Policy Server

There are various RADIUS implementations but in this lab I chose to use Network Policy Server on Windows Server. To set up RADIUS, the Network Policy and Access Services role must be installed and registered in Active Directory so that it can read users' dial-in properties. After installing NPS and registering it in AD I created a RADIUS client that corresponds to the firewall. This involves specifying the IP or FQDN of the firewall and a shared secret. 

![NPS RADIUS Client](<images/Pasted image 20251124210611.png>)

After configuring a RADIUS client, I created a new network policy granting access based on membership in the OpenVPN Users group. MS-CHAP-v2 and v1 was specified as the accepted authentication method. In the future, I will change this to v2 only.

![NPS Network Policy](<images/Pasted image 20251124210858.png>)

![NPS Policy Settings](<images/Pasted image 20251124210938.png>)

![NPS Auth Method](<images/Pasted image 20251124211135.png>)

### Certificate Authority, Authentication and VPN Server

The process of setting up the various components required for OpenVPN on Pfsense involves using the configuration wizard under VPN>OpenVPN>Wizards in the web configurator. I selected RADIUS as the authentication backend, specifying the IP of the network policy server, the shared secret and ports 1812 and 1813 for authentication and accounting, and MS-CHAP-v2 for the authentication protocol. The wizard also prompts you to create a certificate authority, certificate and VPN server. I created a CA named FRWL1_CA and a server certificate for OpenVPN issued by FRWL1_CA.

![OpenVPN Wizard RADIUS](<images/Pasted image 20251128145440.png>)

![OpenVPN CA](<images/Pasted image 20251124220938.png>)

![OpenVPN Certificate](<images/Pasted image 20251124221400.png>)

I configured a server listening on UDP port 1194 and TLS with a TLS key to secure the authentication of client and server. Note that these are the defaults for OpenVPN. The server uses the certificate issued by FRWL1_CA and I specified the network 192.168.254.0/24 for VPN clients. This is a potentially tricky setting, because there is a risk of configuring a network that overlaps with remote users' own home LAN networks. I chose x.x.254.0 because it intuitively feels less common, but that may not be the case. If I were configuring this for production, I may select something less likely to overlap, such a network in the 10.x.x.x/24 range.

Additionally, I specified the internal DNS server running on DC01 as the primary DNS and Cloudflare's DNS as a backup for VPN clients, and pushed a route to the Users subnet.

![OpenVPN Server Config](<images/Pasted image 20251124225619.png>)

I added the route to the Users subnet mainly for testing and experimental purposes. In production I probably would not do this, because I can't think of a reason for VPN clients to have reachability to users on the internal office network. VPN clients typically only need access to internal file shares or need their traffic routed through the company firewall for access to certain locked down resources, for instance a staging or UAT environment hosted in AWS or Azure.

## Client Configuration

There is a package available on Pfsense that allows you to export all client configuration and installation files for OpenVPN. In the package manager, I installed the openvpn-client-export package, and then under OpenVPN>Client Export Utility I exported the configuration and .exe installation file. In order to transfer these files to the test client, I temporarily connected the domain controller directly to my home LAN.

![OpenVPN Client Export](<images/Pasted image 20251128152732.png>)

I installed the OpenVPN client application and imported the configuration file, and that was all required for connectivity on the client side. Domain users in the OpenVPN Users group were able to connect.

![VPN Connect 1](<images/Pasted image 20251128155111.png>)

![VPN Connect 2](<images/Pasted image 20251128155209.png>)

![VPN Connect 3](<images/Pasted image 20251128155248.png>)

![VPN Connect 4](<images/Pasted image 20251128155546.png>)

![VPN Connect 5](<images/Pasted image 20251128155623.png>)

![VPN Connect 6](<images/Pasted image 20251128155701.png>)

The test client has full connectivity and can reach hosts behind the firewall.

## Conclusion

In this article I detailed the steps to configure a remote-access VPN using OpenVPN with RADIUS authentication on Pfsense. To summarize, the steps involve setting up a basic office LAN topology with a Pfsense firewall performing NAT, configuring an Active Directory domain controller and network policy server, then configuring OpenVPN on Pfsense including a CA, server certificate, authentication backend, and VPN server. Client configuration is straight-forward and involves installing the OpenVPN client, importing a configuration file exported from Pfsense and logging in with a domain account with the correct group membership.

## Next Steps

There are an overwhelming array of configuration options in Pfsense. Next steps involve exploring more options, and specifically, configuring a split-tunnel VPN. It usually isn't necessary to force all a client's traffic through the VPN. This needlessly puts more demand on the VPN and resources on the office LAN. Instead, it is a good practice to split client traffic between the VPN and their physical network card. For instance, all traffic needed for a UAT environment or for on-premises file shares would go through the VPN tunnel and other web traffic would go through the client's own default gateway without being tunneled. I plan to explore the configuration of split tunneling as an extension of this lab project.