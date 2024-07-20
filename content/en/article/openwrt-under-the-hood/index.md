---
title: "OpenWRT under hood"
description: "The article shows how OpenWRT config is translated to basic linux configuration utilities calls."
date: 2024-07-08T01:58:40.873Z
draft: false
tags: [openwrt]
categories: [computers, networks]
thumbnail: "/article/openwrt-under-the-hood/thumb.png"
---

## Wireless configuration

Behind the scenes, UCI (Unified Configuration Interface) in OpenWRT uses various command-line utilities and services to apply the wireless configurations defined in `/etc/config/wireless`. Here are some key components and commands involved in this process:

1. **netifd**:
  - The `netifd` (network interface daemon) is responsible for managing network interfaces in OpenWRT. It handles the configuration of interfaces based on the UCI configuration files.

2. **hostapd** and **wpa_supplicant**:
  - OpenWRT typically uses `hostapd` for managing Access Point (AP) interfaces and `wpa_supplicant` for client interfaces. These services are controlled and configured by `netifd` based on the UCI settings.

3. **iw and ip commands**:
  - `netifd` uses `iw` to configure wireless devices and interfaces. It also uses `ip` to manage network interfaces at a lower level.

### Example Workflow

When you configure an SSID in `/etc/config/wireless` and run `wifi reload`, the following steps typically occur:

1. **netifd reads the UCI configuration**:
  - `netifd` parses the `/etc/config/wireless` file to understand the desired configuration for wireless interfaces.

2. **netifd interacts with `hostapd` or `wpa_supplicant`**:
  - If you are configuring an AP, `netifd` will generate a `hostapd` configuration file based on the UCI settings and start/reload `hostapd` with this configuration.
  - For client interfaces, it will do the same with `wpa_supplicant`.

3. **Use of `iw` and `ip` commands**:
  - `netifd` uses `iw` commands to set up the physical and virtual wireless interfaces. For example, it uses `iw dev` to list interfaces, `iw phy` to configure physical wireless settings, and `iw dev interface set` to configure specific settings for a virtual interface.
  - `ip` commands are used to bring interfaces up or down, set IP addresses, and configure other network parameters.

### Example Commands Used by `netifd`

For a given wireless interface setup, the following types of commands might be used:

- **Bringing up an interface**:
  ```sh
  ip link set dev phy0-ap2 up
  ```

- **Setting SSID and other wireless parameters (via `iw`)**:
  ```sh
  iw dev phy0-ap2 set type __ap
  iw dev phy0-ap2 set ssid YourNewSSID
  iw dev phy0-ap2 set channel 6
  ```

- **Starting `hostapd` with a generated configuration**:
  ```sh
  hostapd /var/run/hostapd-phy0.conf
  ```

### Example Configuration and Commands

Here is a more detailed look at how you might see these processes play out:

1. **Configuration in `/etc/config/wireless`**:
  ```sh
  config wifi-device 'radio0'
      option type 'mac80211'
      option channel '6'
      option hwmode '11g'

  config wifi-iface
      option device 'radio0'
      option network 'lan'
      option mode 'ap'
      option ssid 'YourSSID'
      option encryption 'psk2'
      option key 'YourPassphrase'
      option ifname 'phy0-ap2'
  ```

2. **`netifd` generates `hostapd` configuration**:
  ```sh
  interface=phy0-ap2
  driver=nl80211
  ssid=YourSSID
  hw_mode=g
  channel=6
  auth_algs=1
  wpa=2
  wpa_passphrase=YourPassphrase
  wpa_key_mgmt=WPA-PSK
  rsn_pairwise=CCMP
  ```

3. **Commands executed by `netifd`**:
  ```sh
  ip link set dev phy0-ap2 up
  iw dev phy0-ap2 set ssid YourSSID
  iw dev phy0-ap2 set channel 6
  hostapd /var/run/hostapd-phy0.conf
  ```

### An example of real wifi config

```text
cat /etc/config/wireless

config wifi-device 'radio0'
	option type 'mac80211'
	option path 'platform/soc/18000000.wifi'
	option channel '1'
	option band '2g'
	option htmode 'HE20'
	option disabled '0'
	option country 'US'

config wifi-iface 'default_radio0'
	option device 'radio0'
	option network 'lan'
	option mode 'ap'
	option ssid 'tuf-ax4200-2g-0-0'
	option encryption 'psk2'
	option key '12345678'
	option ifname 'vif0'

config wifi-iface 'vif1_radio0'
  option device 'radio0'
  option network 'lan'
  option mode 'ap'
	option ssid 'tuf-ax4200-2g-0-1'
	option encryption 'psk2'
	option key '12345678'
	option ifname 'vif1'

config wifi-device 'radio1'
	option type 'mac80211'
	option path 'platform/soc/18000000.wifi+1'
	option channel '36'
	option band '5g'
	option htmode 'HE80'
	option disabled '0'
	option country 'US'

config wifi-iface 'default_radio1'
	option device 'radio1'
	option network 'lan'
	option mode 'ap'
	option ssid 'tuf-ax4200-5g-1'
	option encryption 'psk2'
	option key '12345678'
```
