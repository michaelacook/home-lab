This repository centralizes my scripts and infrastructure home lab projects for reference and as a record of my progress as an IT professional. I maintain an extensive Obsidian collection of technical notes, and hope to use this repository as an extension of my note collection but tailored specifically to act as a showcase for the project work I found most challenging and gratifying. I also hope that these projects will serve as inspiration for other early-career IT pros to get their hands dirty. If you replicate one of my projects yourself, I would love to hear about your work!

Most of the projects you will find in this collection are related to enterprise networking and server role deployments. However, in the future I hope to share some work related to self-hosting.

## Lab Equipment

Most of the home lab work I do is done using a Dell T7810 workstation with dual Intel Xeon E5-2699 36 core CPUs and 128 GB of ECC memory. I run Proxmox VE on this host, allowing me to easily build out networks in Cisco Modelling Labs and GNS3 and run nearly as many containers and virtual machines as I need. This isn't as expensive as it sounds. For those looking to purchase a similar machine for lab purposes, this kind of setup can be acquired for less than $1000 CAD on eBay.

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
- [Small-Medium Business Infrastructure: Part 1](<projects/smb-active-directory-infrastructure-pt-1/smb-active-directory-infrastructure-pt1.md>) — Hybrid identity doamin, remote access, backup and recovery

<!-- 
### Microsoft 365 and Productivity 
-->

### Networking
- [OpenVPN with RADIUS Authentication](<projects/openvpn-radius-authentication/openvpn-radius-authentication.md>) — VPN remote access with centralized RADIUS-based authentication
- [OpenVPN with RADIUS Authentication – Split Tunneling](<projects/openvpn-radius-authentication-split-tunnel/openvpn-radius-auth-split-tunnel.md>) — Split tunneling configuration for OpenVPN