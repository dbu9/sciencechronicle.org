---
title: "Round-robin load-balancing between two VPNs with iptables and policy-based routing"
description: "The post describes a way to create round-robin balancing between two VPNs using Linux iptables and policy based routing. "
date: 2024-06-09T11:52:37.716Z
draft: false
categories: [Computer, Linux, Networking]
tags: []
thumbnail: "/article/round-robin-load-balancing-between-two-vpns-with-iptables-and-pbr/thumb.png"
---

## Experiment 1

We want to send http traffik generated by our computer through a VPN tunnel.

### VPN tunnels
Create two VPN tunnels:

```bash
openvpn --config au.ovpn
openvpn --config at.ovpn
```

Two new interfaces will be created: `tun0` and `tun1`.

Two configs should prevent setting of default gateways:

```text
pull-filter ignore redirect-gateway
```

### Routing

Create a new routing table:

```bash
echo "201 vpn1" >> /etc/iproute2/rt_tables
```

and add default routing to the table:

```bash
ip route add default dev tun1 table vpn1
```

Check:

```bash
ip route show table vpn1
```

Now, let's add a rule:

```bash
ip rule add from all fwmark 1 lookup vpn1
```

The rule says that packages with mark 0x1 should be routed using table `vpn1`. Effectively, that means, the packages will go to `tun1` interface.

### Marking the packages

```bash
iptables -t mangle -A OUTPUT -p tcp --dport 80 -j MARK --set-mark 1
```

### Testing

Let's try to access some site on port 80:

```bash
curl ipinfo.io
```

The command times out. So what's a problem? The packages are indeed marked with 0x1 and indeed go through `tun1` but they have as source IP not `tun1`'s IP but IP of `eth0` on which `curl` is bound and sends the request. So the packages with SYN flag go through `tun1` interface but ACK packages from the destination are sent to `eth0` IP. 

### Correction 

We should somehow to change source IP of the packages to the IP of `tun1` and when they are back at `tun1` we need to send them back to `eth0` on which `curl` communicates. But that's exactly what NAT MASQUARADE exists for. So, we set `tun1` into that mode:

```bash
iptables -t nat -A POSTROUTING -o tun1 -j MASQUERADE
```

Bingo!

```bash
curl ipinfo.io
```

works through `tun1`.


## Experiment 2

Connections from port 4444 send through vpn1

### Marking packets

Remove previous rules on mangle table:


```bash
iptables -t mangle -F OUTPUT
```

and set new:

```bash
iptables -t mangle -A OUTPUT -p tcp --sport 4444 -j MARK --set-mark 1
```

Because `curl` does not allow to specify source port in its `--interface` option, we'll use `nc`:

```bash
echo -e "GET / HTTP/1.1\r\nHost: ipinfo.io\r\nConnection: close\r\n\r\n" | nc ipinfo.io 80 -p 4444
```

Ok, we get through vpn1. If we remove `-p 4444` command line option, we go through our default interface, not through vpn1.

Note: nat rule on vpn1 is still there. It's a must requirement.

## Randomazing traffik between two VPNs

### Routing

We create two routing tables:

```bash
cat /etc/iproute2/rt_tables
#
# reserved values
#
255	local
254	main
253	default
0	unspec
#
# local
#
#1	inr.ruhep
100 custom_table

200 vpn0
201 vpn1
```

We create default routes in the above  tables:

```bash
ip route add default tun1 table vpn1
ip route add default tun0 table vpn0
```

Check:

```bash
ip route show table vpn1
default dev tun1 scope link 

ip route show table vpn0
default dev tun0 scope link 
```

We create two rules:

```bash
ip rule add from all fwmark 2 lookup vpn0
ip rule add from all fwmark 1 lookup vpn1
```

Check:

```bash
ip rule
0:	from all lookup local
32760:	from all fwmark 0x2 lookup vpn0
32761:	from all fwmark 0x1 lookup vpn1
32766:	from all lookup main
32767:	from all lookup default
```

### Masqurading on VPN interfaces

We should activate nat masquarading on both vpns:

```bash
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun1 -j MASQUERADE
```

### Prevent killing VPN connections

We are going to put all traffik through VPNs, not only to port 80 or from port 4444. Therefore we need to prevent sending VPN client connections to VPN servers:

```bash
iptables -t mangle -A OUTPUT -d 146.70.116.194 -j RETURN
iptables -t mangle -A OUTPUT -d 103.108.231.98 -j RETURN
```

### Marking packets randomly, only those which start connections

The next we want to randomly mark packets. If we just mark *ALL* packets randomly then we destroy the connection. Suppose, SYN packet was marked 1 and sent to tun1. The reponse with SYN-ACK
was delivered to the sending interface ETH1 from VPN but now, ACK package from ETH1 is marked 2 and send to tun0. Thus connection is never established. It was not a case when we had only one VPN interface and all packets were sent to the same VPN interface.

Therefore, we mark only packets which start a connection:

```bash
iptables -t mangle -A OUTPUT -m conntrack --ctstate NEW -m statistic --mode random --probability 0.5 -j MARK --set-mark 2
```

The above marks 50% of connection starting packets. Then we match non-marked packets which start a connection and mark them with 1:

```bash
iptables -t mangle -A OUTPUT -m conntrack --ctstate NEW -m mark --mark 0 -j MARK --set-mark 1
```

Now we want to preserve the marks we gave for all the packets in the connection a marked packet started:

```bash
iptables -t mangle -A OUTPUT -m conntrack --ctstate NEW -j CONNMARK --save-mark
iptables -t mangle -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark
```

The above rules save the mark of a new connection and restore that mark for all the packets in the established connection. The same mark in all packets of the connection guarantees all the
packets arrive at the same VPN interface.

### Summary

Masquarade:

```bash
iptables -t nat -L -v -n
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
  148 13070 MASQUERADE  all  --  *      tun1    0.0.0.0/0            0.0.0.0/0           
  203 17720 MASQUERADE  all  --  *      tun0    0.0.0.0/0            0.0.0.0/0   
```

Mangle:

```bash
iptables -t mangle -L -v -n
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
 7839 1001K RETURN     tcp  --  *      *       0.0.0.0/0            146.70.116.194      
55156 8718K RETURN     tcp  --  *      *       0.0.0.0/0            103.108.231.98      
  377 32241 MARK       all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW statistic mode random probability 0.50000000000 MARK set 0x2
  274 30364 MARK       all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW mark match 0x0 MARK set 0x1
  493 48897 CONNMARK   all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW CONNMARK save
 1658  224K CONNMARK   all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED CONNMARK restore

Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
```

Routing tables:

```bash
cat /etc/iproute2/rt_tables
#
# reserved values
#
255	local
254	main
253	default
0	unspec
#
# local
#
#1	inr.ruhep
100 custom_table

200 vpn0
201 vpn1
```

Routing table routes:

```bash
ip route show table vpn1
default dev tun1 scope link 

ip route show table vpn0
default dev tun0 scope link 
```

Routing rules:

```bash
ip rule
0:	from all lookup local
32760:	from all fwmark 0x2 lookup vpn0
32761:	from all fwmark 0x1 lookup vpn1
32766:	from all lookup main
32767:	from all lookup default
```


## References

1. [https://datahacker.blog/industry/technology-menu/networking/routes-and-rules/iproute-and-routing-tables](https://datahacker.blog/industry/technology-menu/networking/routes-and-rules/iproute-and-routing-tables)
2. [https://www.frozentux.net/iptables-tutorial/chunkyhtml/c962.html#TABLE.FORWARDEDPACKETS](https://www.frozentux.net/iptables-tutorial/chunkyhtml/c962.html#TABLE.FORWARDEDPACKETS)
3. [https://book.huihoo.com/iptables-tutorial/x9125.htm](https://book.huihoo.com/iptables-tutorial/x9125.htm)