# Home Lab Portfolio

This repository documents my home lab infrastructure projects, covering enterprise networking, server role deployments, and cloud integration. It serves as both a technical reference and a showcase of my hands-on work as an IT professional.

## Equipment

Most of the home lab work I do is done using a Dell T7810 workstation with dual Intel Xeon E5-2699 36 core CPUs and 128 GB of ECC memory. I run Proxmox VE 9 on this host, allowing me to easily build out networks in Cisco Modelling Labs and GNS3 and run as many containers and virtual machines as I need. For those looking to create a similar lab environment, a refurbished Dell or HP workstation with similar specifications can be obtained on eBay for 700 - 1000 CAD.

## Projects

Projects are organized into the following categories: AI, Automation, Compute & Virtualization, Infrastructure, Identity & Access, Microsoft 365 and Productivity, and Networking. Categories without projects are commented out until they have content.

<!-- 
### AI
### Automation
### Compute and Virtualization 
-->

### Infrastructure, Identity & Access
- [Configuring an Active Directory Forest Trust](<projects/active-directory-forest-trust/active-directory-forest-trust.md>) — Two-way trust between two Active Directory forests
- [Office Domain: Cooklab.local](<projects/smb-active-directory-infrastructure-segmented/active-directory-infrastructure-segmented.md>) — Core SMB domain with segmentation, network services, and file sharing
- [Small-Medium Business Infrastructure: Part 1](<projects/smb-active-directory-infrastructure-pt-1/article.md>) — Initial setup, forest creation, and directory configuration
- [Small-Medium Business Infrastructure: Part 2](<projects/smb-active-directory-infrastructure-pt-2/article.md>) — Configuring Hybrid Identity with Entra Connect Sync

<!-- 
### Microsoft 365 and Productivity 
-->

### Networking
- [OpenVPN with RADIUS Authentication](<projects/openvpn-radius-authentication/openvpn-radius-authentication.md>) — VPN remote access with centralized RADIUS-based authentication
- [OpenVPN with RADIUS Authentication – Split Tunneling](<projects/openvpn-radius-authentication-split-tunnel/openvpn-radius-auth-split-tunnel.md>) — Split tunneling configuration for OpenVPN