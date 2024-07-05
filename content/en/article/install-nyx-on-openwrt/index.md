---
title: "Install NYX on OpenWRT"
description: "This short article is about installation of NYX on OpenWRT 23.05.3 r23809-234f1a2efa. With precompiled binaries of stem module NYX fails to start due to getargspec()."
date: 2024-06-04T02:58:40.873Z
draft: false
tags: [openwrt, nyx, tor]
categories: [Computers]
thumbnail: "/article/install-nyx-on-openwrt/thumb.png"
---

[NYX](https://nyx.torproject.org/) is a monitoring utility for TOR. It connects to Tor's control port so to make it work we should define the control port in `/etc/tor/torrc`:

```bash
# File: /etc/tor/torrc
ControlPort 9051
```

Install NYX on [OpenWRT](https://openwrt.org/toh/asus/tuf-ax4200) version 23.05.3 r23809-234f1a2efa with the following commands:

```bash
opkg update
opkg install nyx
```

When running, we get into an error:

```bash
nyx
Traceback (most recent call last):
  File "/usr/bin/nyx", line 8, in <module>
    sys.exit(main())
             ^^^^^^
  File "/usr/lib/python3.11/site-packages/nyx/__init__.py", line 176, in main
  File "/usr/lib/python3.11/site-packages/stem/util/conf.py", line 288, in wrapped
AttributeError: module 'inspect' has no attribute 'getargspec'. Did you mean: 'getargs'?
```

To solve that problem, we proceed as follows:

```bash
opkg update
opkg install python3-pip
```

When trying to upgrade nyx we get that's all ok:

```bash
opkg update
pip3 install --upgrade nyx
```

but the error persists when running nyx.

The problem is due to `stem` package which comes as compiled python code. 

We uninstall `stem` and reinstall it without binaries:

```bash
pip uninstall stem
Found existing installation: stem 1.8.1
Uninstalling stem-1.8.1:
  Would remove:
    /usr/bin/tor-prompt
    /usr/lib/python3.11/site-packages/stem-1.8.1.dist-info/*
    /usr/lib/python3.11/site-packages/stem/cached_fallbacks.cfg
    /usr/lib/python3.11/site-packages/stem/cached_manual.sqlite
    /usr/lib/python3.11/site-packages/stem/interpreter/settings.cfg
    /usr/lib/python3.11/site-packages/stem/settings.cfg
    /usr/lib/python3.11/site-packages/stem/util/ports.cfg
Proceed (Y/n)? 
  Successfully uninstalled stem-1.8.1
WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager. It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv
```

and

```bash
pip install stem --no-binary :all:
Collecting stem
  Downloading stem-1.8.2.tar.gz (2.9 MB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 2.9/2.9 MB 5.3 MB/s eta 0:00:00
  Installing build dependencies ... done
  Getting requirements to build wheel ... done
  Preparing metadata (pyproject.toml) ... done
Building wheels for collected packages: stem
  Building wheel for stem (pyproject.toml) ... done
  Created wheel for stem: filename=stem-1.8.2-py3-none-any.whl size=436205 sha256=9b6843ba83aadc60f4dbe277e3b2f2db7df5f5f365044ec7f6d811e0d84d3de6
  Stored in directory: /tmp/cache/pip/wheels/a8/52/ae/ba7ad30bbb36c7b4bb65e1d08793b3c87fd49dd0395bd4fe34
Successfully built stem
Installing collected packages: stem
Successfully installed stem-1.8.2
WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager. It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv
```

Now we are able to run nyx.
