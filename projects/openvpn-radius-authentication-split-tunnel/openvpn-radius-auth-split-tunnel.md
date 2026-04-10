# OpenVPN Split Tunneling
In a previous post, I detailed the steps I took to configure OpenVPN on Pfsense using RADIUS for authentication. This is a short follow-up post to discuss split tunneling.
## Topology
![Topology](images/topology.png)
## What is split tunneling?
By default, when a client device connects into a remote network via a VPN, all traffic from the client will be tunneled to that remote network. I may be connecting to my office network so I can access a file share, but unless configured otherwise, not only traffic to that file server but also all my web traffic will go through the office network. In a lot of situations, this is really inefficient. If I just need to access a file share, I don't need all my web traffic to be tunneled through the VPN just to go back out the office network's gateway. This will reduce performance for me, and increase load on the office firewall. A split tunnel allows the administrator to configure which traffic from clients should be tunneled, and which shouldn't.
## Configuring the split tunnel
As it turns out, configuring a split tunnel for OpenVPN on Pfsense is very simple. In the OpenVPN Server configuration under tunnel settings, there is the option **Redirect IPv4 Gateway: Force all client-generated IPv4 traffic through the tunnel**. When this option is unchecked, only the subnets specified under **Tunnel Settings** and **Advanced Configuration** will be tunneled. I have already specified the subnet 192.168.200.0/24 under **Tunnel Settings>IPv4 Local network(s)**, but also pushed out a route for the users subnet 192.168.100.0/24 for testing purposes.
![](<images/Pasted image 20251211220148.png>)
![](<images/Pasted image 20251211220236.png>)
## Testing routes
We view the client's route table using `print route`. When the client is connected to the VPN, only traffic destined for 192.168.200.0/24 and 192.168.100.0/24 will go through the virtual gateway 195.168.254.1. All other traffic will use the client's default route to it's own local gateway at 192.168.127.1.
![](<images/Pasted image 20251211220642.png>)
We can confirm that regular traffic will go out via the client's local gateway using `tracert`. I pinged duckduckgo.com, and observed that the first hop address is 192.168.127.1, but if we trace the path to the cooklab.local domain controller, it goes through the VPN virtual gateway.
![](<images/Untitled 1.png>)
It is worth noting that it isn't actually necessary to specify routes under **Advanced Configuration** in the VPN server settings on Pfsense. Instead, all networks that should be tunneled can be specified under **Tunnel Settings** in a comma-separated list. I tested this and got the same result in the client routing table.
## Summary
In this short post I demonstrated the settings required to configure a split-tunnel VPN with OpenVPN on Pfsense. Configuration is straight-forward and involves unchecking the setting to force all traffic through the VPN tunnel, then specifying the networks that should be tunneled.