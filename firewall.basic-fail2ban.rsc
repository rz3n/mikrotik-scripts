# ------------------- header -------------------
# Script by Ricardo Franzen - rfranzen<at>gmail.com
# If you use this script, or edit and
# re-use it, please keep the header intact.
# Description: Basic firewall rules for RouterOS with a function like fail2ban to block ssh and winbox excessive attempts
# Tested on: > routeros v6.36
# ------------------- header -------------------

/interface list
add name=wan.interfaces
add name=lan.interfaces

## Address lists
/ip firewall address-list
add address=trusted.mydomain.com list=trusted-ips
add address=0.0.0.0/8 		comment="RFC 1122 \"This host on this network\"" disabled=yes list=Bogons
add address=10.0.0.0/8 		comment="RFC 1918 (Private Use IP Space)" disabled=yes list=Bogons
add address=100.64.0.0/10 	comment="RFC 6598 (Shared Address Space)" disabled=yes list=Bogons
add address=127.0.0.0/8 	comment="RFC 1122 (Loopback)" disabled=yes list=Bogons
add address=169.254.0.0/16 	comment="RFC 3927 (Dynamic Configuration of IPv4 Link-Local Addresses)" disabled=yes list=Bogons
add address=172.16.0.0/12 	comment="RFC 1918 (Private Use IP Space)" disabled=yes list=Bogons
add address=192.0.0.0/24 	comment="RFC 6890 (IETF Protocol Assingments)" disabled=yes list=Bogons
add address=192.0.2.0/24 	comment="RFC 5737 (Test-Net-1)" disabled=yes list=Bogons
add address=192.168.0.0/16 	comment="RFC 1918 (Private Use IP Space)" disabled=yes list=Bogons
add address=198.18.0.0/15 	comment="RFC 2544 (Benchmarking)" disabled=yes list=Bogons
add address=198.51.100.0/24 comment="RFC 5737 (Test-Net-2)" disabled=yes list=Bogons
add address=203.0.113.0/24 	comment="RFC 5737 (Test-Net-3)" disabled=yes list=Bogons
add address=224.0.0.0/4 	comment="RFC 5771 (Multicast Addresses) - Will affect OSPF, RIP, PIM, VRRP, IS-IS, and others. Use with caution.)" disabled=yes list=Bogons
add address=240.0.0.0/4 	comment="RFC 1112 (Reserved)" disabled=yes list=Bogons
add address=192.31.196.0/24 comment="RFC 7535 (AS112-v4)" disabled=yes list=Bogons
add address=192.52.193.0/24 comment="RFC 7450 (AMT)" disabled=yes list=Bogons
add address=192.88.99.0/24 	comment="RFC 7526 (Deprecated (6to4 Relay Anycast))" disabled=yes list=Bogons
add address=192.175.48.0/24 comment="RFC 7534 (Direct Delegation AS112 Service)" disabled=yes list=Bogons
add address=255.255.255.255 comment="RFC 919 (Limited Broadcast)" disabled=yes list=Bogons

## Enable connection tracking
/ip firewall connection tracking
set enabled=yes


/ip firewall filter
## Drop invalid
add action=drop chain=input comment="# drop invalid connections - input" connection-state=invalid
add action=drop chain=forward comment="# drop invalid connections - forward" connection-state=invalid in-interface-list=lan.interfaces

## Trusted IP's Access
add action=accept chain=input comment="# trusted ip's" src-address-list=trusted-ips

## Accept icmp-ping
add action=accept chain=input comment="# accept icmp-ping" protocol=icmp

## Drop wan access (telnet, ftp, www) to mikrotik
add action=drop chain=input comment="# drop telnet,ftp,www from wan" dst-port=21,23,80 in-interface-list=wan.interfaces protocol=tcp
add action=drop chain=input comment="# drop dns,ntp from wan" dst-port=53,123 in-interface-list=wan.interfaces protocol=udp

## Drop fail2ban ssh list
add action=drop chain=input comment="# drop address from list fail2ban SSH" dst-port=22 protocol=tcp src-address-list=fail2ban-ssh
add action=drop chain=forward comment="# drop address from list fail2ban SSH" dst-port=22 protocol=tcp src-address-list=fail2ban-ssh
## Drop fail2ban winbox list
add action=drop chain=input comment="# drop address from list fail2ban Winbox" dst-port=8291 protocol=tcp src-address-list=fail2ban-winbox
add action=drop chain=forward comment="# drop address from list fail2ban Winbox" dst-port=8291 protocol=tcp src-address-list=fail2ban-winbox
## Drop fail2ban portscanners list
add action=drop chain=input comment="# drop address from list WAN Port Scanners" src-address-list="WAN Port Scanners"
add action=drop chain=forward comment="# drop address from list WAN Port Scanners" src-address-list="WAN Port Scanners"
## Drop blacklist
add action=drop chain=input comment="# drop address from list blacklist" disabled=yes src-address-list=blacklist
add action=drop chain=forward comment="# drop address from list blacklist" disabled=yes src-address-list=blacklist
## Drop p2p
add action=drop chain=forward comment="# drop all P2P - TEST" disabled=yes p2p=all-p2p

## Detect & Block brute force ssh connection attempts
add action=accept chain=output comment="**** section break ****" disabled=yes
add action=jump chain=input comment="## jump to fail2ban-ssh chain" dst-port=22 jump-target=fail2ban-ssh protocol=tcp
add action=add-src-to-address-list address-list=fail2ban-ssh address-list-timeout=30m chain=fail2ban-ssh comment="# drop for 30m after repeated attempts" connection-state=!established,related dst-port=22 protocol=tcp src-address-list=fail2ban-ssh-t3
add action=add-src-to-address-list address-list=fail2ban-ssh-t3 address-list-timeout=1m chain=fail2ban-ssh comment="# SSH attempt 3" connection-state=new dst-port=22 protocol=tcp src-address-list=fail2ban-ssh-t2
add action=add-src-to-address-list address-list=fail2ban-ssh-t2 address-list-timeout=1m chain=fail2ban-ssh comment="# SSH attempt 2" connection-state=new dst-port=22 protocol=tcp src-address-list=fail2ban-ssh-t1
add action=add-src-to-address-list address-list=fail2ban-ssh-t1 address-list-timeout=1m chain=fail2ban-ssh comment="# SSH attempt 1" connection-state=new dst-port=22 protocol=tcp
add action=return chain=fail2ban-ssh comment="## return from fail2ban-ssh chain"

## Detect & Block brute force winbox connection attempts
add action=accept chain=output comment="**** section break ****" disabled=yes
add action=jump chain=input comment="## jump to fail2ban-winbox chain" dst-port=8291 jump-target=fail2ban-winbox protocol=tcp
add action=add-src-to-address-list address-list=fail2ban-winbox address-list-timeout=30m chain=fail2ban-winbox comment="# drop for 30m after repeated attempts" connection-state=new dst-port=8291 protocol=tcp src-address-list=fail2ban-winbox-t3
add action=add-src-to-address-list address-list=fail2ban-winboxwinbox-t3 address-list-timeout=1m chain=fail2ban-winbox comment="# winbox attempt 3" connection-state=new dst-port=8291 protocol=tcp src-address-list=fail2ban-winbox-t2
add action=add-src-to-address-list address-list=fail2ban-winbox-t2 address-list-timeout=1m chain=fail2ban-winbox comment="# winbox attempt 2" connection-state=new dst-port=8291 protocol=tcp src-address-list=fail2ban-winbox-t1
add action=add-src-to-address-list address-list=fail2ban-winbox-t1 address-list-timeout=1m chain=fail2ban-winbox comment="# winbox attempt 1" connection-state=new dst-port=8291 protocol=tcp
add action=return chain=fail2ban-winbox comment="## return from fail2ban-winbox chain"

## Detect & Block port scanners connection attempts
add action=accept chain=output comment="**** section break ****" disabled=yes
add action=add-src-to-address-list address-list="WAN Port Scanners" address-list-timeout=30m chain=input comment="# add TCP Port Scanners to Address List" protocol=tcp psd=40,3s,2,1
add action=add-src-to-address-list address-list="LAN Port Scanners" address-list-timeout=30m chain=forward comment="# add TCP Port Scanners to Address List" protocol=tcp psd=40,3s,2,1

## Detect hight connection rates
add action=accept chain=output comment="**** section break ****" disabled=yes
add action=add-src-to-address-list address-list="WAN High Connection Rates" address-list-timeout=30m chain=input comment="# add WAN High Connections to Address List - TEST" connection-limit=100,32 disabled=yes protocol=tcp
add action=add-src-to-address-list address-list="LAN High Connection Rates" address-list-timeout=30m chain=forward comment="# add LAN High Connections to Address List - TEST" connection-limit=100,32 disabled=yes protocol=tcp

## Accept established and related connections
add action=accept chain=input comment="# accept Related or Established Connections" connection-state=established,related
add action=accept chain=forward comment="# accept New Connections" connection-state=new
add action=accept chain=forward comment="# accept Related or Established Connections" connection-state=established,related

## Accept SSH connections if is not in block list
add action=accept chain=input comment="# accept from !fail2ban SSH" dst-port=22 protocol=tcp src-address-list=!fail2ban-ssh
add action=accept chain=forward comment="# accept from !fail2ban SSH" dst-port=22 protocol=tcp src-address-list=!fail2ban-ssh
## Accept Winbox connections if is not in block list
add action=accept chain=input comment="# accept from !fail2ban Winbox" dst-port=8291 protocol=tcp src-address-list=fail2ban-winbox
add action=accept chain=forward comment="# accept from !fail2ban Winbox" dst-port=8291 protocol=tcp src-address-list=fail2ban-winbox

## Drop all
add action=drop chain=forward comment="# drop all other LAN Traffic"
add action=drop chain=input comment="# drop all other WAN Traffic"

## Masquerade wan output
/ip firewall nat
add action=masquerade chain=srcnat out-interface-list=wan.interfaces

## Services
/ip service
set ftp 	address="" disabled=no 	port=21
set www 	address="" disabled=no 	port=80
set ssh 	address="" disabled=no 	port=22
set winbox 	address="" disabled=no 	port=8291
set telnet 	address="" disabled=yes port=23
set api 	address="" disabled=yes port=8728
set api-ssl address="" certificate=none disabled=yes port=8729
set www-ssl address="" certificate=none disabled=yes port=443

/