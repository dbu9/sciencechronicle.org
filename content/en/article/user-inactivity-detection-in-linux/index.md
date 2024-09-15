---
title: "User inactivity detection in Linux"
description: "In this article we review and test methods of user inactivity detection in Linux, both for terminal and UI environments."
date: 2024-08-01T03:58:40.873Z
draft: false
categories: [Linux, Computer]
tags: [linux]
thumbnail: "/article/user-inactivity-detection-in-linux/thumb.png"
---

We want to detect user inactivity on Linux system in a bash service run by systemd. Why? When user is inactive, we can launch some CPU-heavy tasks without disrupting user's interaction with the system.

A user has 2 primary ways of interaction with Linux system: through textual terminal or UI desktop like Cinnamon, Xface, etc. The methods of user (in)activity detection are different for terminal and UI. 

## UI environment

We conduct our tests on Linux Mint 20.3 (Una) with MATE 1.26.0, Linux Kernel 5.15.0-121.

`xprintidle` seems a perfect solution for detection of user inactivity in Mate UI. The utility is not installed
by default, however.

Here is a one-liner to test the utility. Run it in a terminal session under Mate:

```bash
while true; do echo "$(date)|$(xprintidle)"; sleep 10; done
```

A sample output:

```text
Sun 15 Sep 2024 17:12:52 IDT|1
Sun 15 Sep 2024 17:13:02 IDT|55
Sun 15 Sep 2024 17:13:12 IDT|712
Sun 15 Sep 2024 17:13:22 IDT|449
Sun 15 Sep 2024 17:13:32 IDT|68
Sun 15 Sep 2024 17:13:42 IDT|6062
Sun 15 Sep 2024 17:13:52 IDT|16072
Sun 15 Sep 2024 17:14:02 IDT|26081
Sun 15 Sep 2024 17:14:12 IDT|36092
Sun 15 Sep 2024 17:14:22 IDT|46102
```

We checked the following UI managers where `xprintidle` works as expected.

|OS|UI|xprintidle|Available in repo|
|--|--|----------|-----------------|
|Linux Mint 20.3 (una)|Mate 1.26.0|😀|😀|
|Linux Mint 21.3 (virginia)|Xface 4|😀|😀|
|Fedora Linux 40|Cinnamon|😀|😕 (manual compilation|

### How to manually compile xprintidle on Fedora

```bash
sudo dnf install gcc make libX11-devel libXtst-devel
git clone https://github.com/lucianposton/xprintidle
cd xprintidle
./configure
make
make install
```
