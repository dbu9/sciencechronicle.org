---
title: "User inactivity detection in Linux"
description: "In this article we review and test methods of user inactivity detection in Linux, both for terminal and UI environments."
date: 2024-09-17T03:58:40.873Z
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

## Terminal envorinment 

We have two methods to check user activity in terminal environment: `who` command and `ls /dev/pts`.

We logged in to two amazon instances using ssh.

```bash
who -u
ubuntu   pts/12       2024-09-01 11:09  old       181334 (:pts/0:S.0)
ubuntu   pts/13       2024-09-17 23:42 00:03      264853 (1.139.2.1)
ubuntu   pts/14       2024-09-17 23:44   .        264969 (1.139.2.1)
```

In the 5th column of the outout, the time indicates inactivity period in hours:minutes. The first row (old) indicates the session on PTS 12 is inactive more than 60 mins. The second row shows the session on PTS 13 is inactive for 3 minutes. The third row shows the session on PTS 14 is currently active.

We can also check `/dev/pts` folder:

```bash
ls -l /dev/pts
total 0
crw--w---- 1 ubuntu tty  136,  1 Sep  9 11:26 1
crw--w---- 1 ubuntu tty  136, 10 Sep  9 11:25 10
crw--w---- 1 ubuntu tty  136, 11 Sep 18 00:00 11
crw--w---- 1 root   tty  136, 12 Sep  1 13:15 12
crw--w---- 1 ubuntu tty  136, 13 Sep 17 23:51 13
crw--w---- 1 ubuntu tty  136, 14 Sep 18 00:00 14
crw--w---- 1 ubuntu tty  136,  2 Sep  9 11:26 2
crw--w---- 1 ubuntu tty  136,  3 Sep  9 11:26 3
crw--w---- 1 ubuntu tty  136,  4 Sep  9 11:26 4
crw--w---- 1 ubuntu tty  136,  5 Sep  9 11:26 5
crw--w---- 1 ubuntu tty  136,  6 Sep  9 11:26 6
crw--w---- 1 ubuntu tty  136,  7 Sep 17 23:42 7
crw--w---- 1 ubuntu tty  136,  8 Sep  9 11:26 8
crw--w---- 1 ubuntu tty  136,  9 Sep  1 13:15 9
c--------- 1 root   root   5,  2 Jul 30 23:12 ptmx
```

The session on PTS 13 was active on Sep 17 23:51. The session on PTS 14 was active on 14 Sep 18 00:00 14. 

## How to know if user is in UI or in text session

There is a simple way to detect if user is working under some UI environment using `who` command:

```bash
who -u
user  tty7         2024-09-13 03:07  old         4673 (:0)
```

The :0 suffix indictaes display. That's a mark for UI. The command was run from terminal under MATE UI on Linux Mint.


Note:

```bash
who -u
ubuntu   pts/12       2024-09-01 11:09  old       181334 (:pts/0:S.0)
ubuntu   pts/13       2024-09-17 23:42 00:03      264853 (1.139.2.1)
ubuntu   pts/14       2024-09-17 23:44   .        264969 (1.139.2.1)
```

the lacking :0 suffix on amazon instance without X installed. 