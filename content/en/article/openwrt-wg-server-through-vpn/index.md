---
title: "OpenWRT with WireGuard server which is connected through OpenVPN"
description: "In this blog we show how to setup Wireguard server connected through VPN on a OpenWRT router."
date: 2024-07-18T01:58:40.873Z
draft: false
tags: [openwrt, vpn, wireguard]
categories: [computers, networks]
thumbnail: "/article/openwrt-wg-server-through-vpn/thumb.png"
---

We setup a wireguard server on an OpenWRT router. We generate a setup file for the client. The wireguard server itself we connect through a VPN. The VPN itself can be socked through TOR (we don't discuss this in the article). 

## Generate keys 

```bash
umask go=
wg genkey | tee wgserver.key | wg pubkey > wgserver.pub
wg genkey | tee wgclient.key | wg pubkey > wgclient.pub
wg genpsk > wgclient.psk
```

## Setup wireguard server

Note, wireguard server is actually a kernel module and there is no a special application to be run. The wireguard module exposes interface to `ip link` with which one can create a device of type `wireguard`.

In OpenWRT router we define a network interface with protocol of `wireguard`. 

```bash
uci -q delete network.styx;
uci set network.styx='interface';
uci set network.styx.proto='wireguard';
uci set network.styx.private_key='kKoONE1SO5x94fCJqrKV52mAxwIvgnpK7hAlPpt1R3I=';
uci set network.styx.listen_port='52820';
uci add_list network.styx.addresses='192.168.5.1/24';

uci -q delete network.wgclient`;
uci set network.wgclient='wireguard_styx';
uci set network.wgclient.public_key='9k5F5LsZKWR7wEqURgc4cVKTRgd31rayGtxSMrFYmgU='`;
uci set network.wgclient.preshared_key='ASsDWeoB8tdj5hTuPHNOocqnk7nNeSqt7s5y5aFn+XI=';
uci add_list network.wgclient.allowed_ips='192.168.5.2/32';

uci commit network`;
/etc/init.d/network reload`;
```

We defined interface `styx` with listening port `52820` and assigned default gateway `192.168.5.1` with mask `255.255.255.0`. The `private_key` was taken from `wgserver.key`.
The network `wgclient` allows only one host `192.168.5.2/32`. The `public_key` was taken from `wgclient.pub` and `preshared_key` was taken from `wgclient.psk`. 

## Setup wireguard client

On client (laptop) side, we use the following commands to setup `wg0` device:

```bash
#!/bin/bash
ip link add dev wg0 type wireguard
# Set private key and IP address
wg set wg0 private-key <(echo +PiLMRXfFrIOMuiR7DK1XNj0QYkmQnGBszXrip1NKFA=)
ip address add 192.168.5.2/24 dev wg0

# Optional: Set DNS
# echo "nameserver 8.8.8.8" | resolvconf -a wg0

# Configure the peer
wg set wg0 peer Lp1/m57JlYM5UXVhfEUpV6RTXy5rIjcOPrgboRaP7gE= preshared-key <(echo ASsDWeoB8tdj5hTuPHNOocqnk7nNeSqt7s5y5aFn+XI=) endpoint 87.23.56.3:52820 allowed-ips 0.0.0.0/0 persistent-keepalive 25

# Bring up the interface
ip link set up dev wg0
```

We used `private-key` taken from `wgclient.key` and `peer` taken from `wgserver.pub`. The `endpoint` is public IP of our router and the port is the one used for listening. If the OpenWRT router is connected to ISP router, we need to setup port forwarding for the port. 

## Setup OpenWRT firewall

To simplify testing, we just allow everything on the firewall:

```bash
nft flush ruleset
nft -f all-accept.nft
```

where `all-accept.nft` is


```text
table inet fw4 {
	chain forward {
		type filter hook forward priority filter; policy accept;
	}

	chain input {
		type filter hook input priority filter; policy accept;
	}

	chain output {
		type filter hook output priority filter; policy accept;
	}

	chain srcnat {
		type nat hook postrouting priority srcnat; policy accept;
		oifname "eth1" meta nfproto ipv4 masquerade
	}

	chain prerouting {
		type filter hook prerouting priority filter; policy accept;
	}
}
```

Now we can connect through `wg0` on the client:

```bash
curl --interface w0 ipinfo.io
```

and we should get our router's external ip.

## Run OpenVPN on the router without default route change

We use mullvad open vpn setup file in which `up` and `down` directives are commented out. Then

```bash
openvpn --config mullvad_at_all.conf --route-nopull 
```

We got the vpn on `tun0`:

```bash
ifconfig
tun0  Link encap:UNSPEC  HWaddr 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00  
			inet addr:10.5.0.16  P-t-P:10.5.0.16  Mask:255.255.0.0
			inet6 addr: fdda:d0d0:cafe:443::100e/64 Scope:Global
			inet6 addr: fe80::5378:9544:a3c3:54b/64 Scope:Link
			UP POINTOPOINT RUNNING NOARP MULTICAST  MTU:1500  Metric:1
			RX packets:53 errors:0 dropped:0 overruns:0 frame:0
			TX packets:64 errors:0 dropped:0 overruns:0 carrier:0
			collisions:0 txqueuelen:500 
			RX bytes:5331 (5.2 KiB)  TX bytes:8507 (8.3 KiB)
```

We can test the interface:

```bash
curl --interface tun0 ipinfo.io
```

## Setting routing 

We create `styx` table for rule based routing:

```bash
echo '256 styx' >> /etc/iproute2/rt_tables
```

and add a default route to itthrough our vpn:

```bash
ip rule add default 10.5.0.16 dev tun0 
```

The we create a rule which route the traffik from `styx` interface to `tun0`:

```bash
ip rule add from all iif styx lookup styx
```


Because forwarding policy in our firewall is `accept` by default, we don't need to explicitly allow the forwarding. However, we need masquerading, as always for interfaces which are used for external communication:

```bash
nft add rule inet fw4 srcnat oifname "tun0" meta nfproto ipv4 masquerade
```

## Firewall with default drop policies

If firewall forwarding policy is default to `drop` then we need to add:

```bash
nft add rule inet fw4 forward ct state established,related accept
nft add rule inet fw4 forward iifname "br-lan" oifname "eth1" accept
nft add rule inet fw4 forward iifname "styx" oifname "tun0" accept
```

If firewall input policy is defauly to `drop` then we need to add:

```bash
nft add rule inet fw4 input iifname "lo" accept
nft add rule inet fw4 input ct state established,related accept
nft add rule inet fw4 input iifname "br-lan" accept
nft add rule inet fw4 input iifname "styx" accept
```

The interface `lo` must be added for normal functioning. The interface `br-lan` should be added to not lose access to the router through cable onlan ports.

The full firewall setup:

```text
table inet fw4 {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct state established,related accept
		iifname "styx" oifname "tun0" meta nfproto ipv4 accept
		iifname "br-lan" oifname "eth1" meta nfproto ipv4 accept
	}

	chain input {
		type filter hook input priority filter; policy drop;
		ct state established,related accept
		iifname "lo" accept
		iifname "br-lan" accept
	}

	chain output {
		type filter hook output priority filter; policy accept;
	}

	chain srcnat {
		type nat hook postrouting priority srcnat; policy accept;
		oifname "eth1" meta nfproto ipv4 masquerade
		oifname "tun0" meta nfproto ipv4 masquerade
	}

	chain prerouting {
		type filter hook prerouting priority filter; policy accept;
	}
}
```

## Summary

