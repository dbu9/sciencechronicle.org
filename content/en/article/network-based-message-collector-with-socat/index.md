---
title: "Network based message collector with socat"
description: "A method to collect messages from linux hosts to a centralized server with built-in utilities is described. Differently colored hats can find it useful."
date: 2024-05-30T11:52:37.716Z
draft: false
categories: [Computer, Linux, Networking]
tags: [socat, linux, message collector]
thumbnail: "/article/network-based-message-collector-with-socat/thumb.jpg"
---

## Overview

The simplest message collector code can be implemented with `socat`:

```bash
socat -u TCP4-LISTEN:4444,reuseaddr,fork OPEN:/tmp/log.txt,creat,append
```

It will listen on tcp port 4444, it can accept multiple simultaneous connections which guarantees no connection is refused and it will write the data recieved on the port to `/tmp/log.txt`, appending to the file if it already exists or creating a new if it does not.

The sender can be implemented in many ways, for example:

*using nc*:

```bash
echo "Hello, World!" | nc -q 0 localhost 4444
```

The `-q 0` makes nc to close the connection after the data is sent.

*using socat*:

```bash
echo "hello world" | socat - TCP4:localhost:4444
```

*using python*:

```python
import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(("localhost", 4444))
s.sendall(b"hello world\n")
s.close()
```

*using /dev/tcp*:

```bash
echo "Hello, World!" > /dev/tcp/localhost/4444
```

The later method is delightful as it does not depend on any utility. 

## Improvement

The above collector can be easily abused. Opened to the external world, anyone can send to it ton of data and fill the hard disk causing denial of service. So we want to implement a simple protection with a keyword.

Let's create a bash script, `sink2.sh`:

```bash
#!/bin/bash

# This script reads from:
# socat -u TCP4-LISTEN:4444,reuseaddr,fork EXEC ./sink2.sh

# Send to socat:
# cat testnfo.txt > /dev/tcp/localhost/4444


input_allowed=0
line_number=0
keyword=RX203
while IFS= read -r line; do 
(( line_number++ ))
	if [[ $line_number == 1 ]]; then
		if [[ $line == $keyword ]]; then
			input_allowed=1
		fi
	fi
	if [[ $input_allowed == 1 ]]; then
  	echo $line_number: $line
	fi
done
```

and run it with `socat` as 

```bash
 socat -u TCP4-LISTEN:4444,reuseaddr,fork EXEC ./sink2.sh
```

Now, let's try to send some data to it:

```bash
echo "Hello, World!" > /dev/tcp/localhost/4444
```

Nothing is printed.

Now lets send a keyword defined as `RX203` to the collector:

```bash
echo -n "RX203\nHello, World!" > /dev/tcp/localhost/4444
```

Ok, we got the message.

So, our `sink2.sh` script checks if the first line of the input equals to `keyword` and if not, it does not read and does not echo the rest of the input, thus preventig "unauthorized" messages from logging.

## Making socat behave as a daemon

To ensure `socat` runs persistently and behaves like a server, you can use several methods.

### 1. Using `screen`

`screen` allows you to run `socat` in a detached session that will persist even if you log out.


1. **Start a new screen session**:

   ```sh
   screen -S socat_server
   ```

2. **Run the `socat` command** within the screen session:

   ```sh
   socat -u TCP4-LISTEN:4444,reuseaddr,fork EXEC ./sink2.sh
   ```

3. **Detach from the screen session** by pressing `Ctrl+a` then `d`.

4. **To reattach to the screen session** later, use:

   ```sh
   screen -r socat_server
   ```

### 2. Using `tmux`

`tmux` is similar to `screen` and allows for managing multiple terminal sessions.

1. **Start a new `tmux` session**:

   ```sh
   tmux new -s socat_server
   ```

2. **Run the `socat` command** within the `tmux` session:

   ```sh
   socat -u TCP4-LISTEN:4444,reuseaddr,fork EXEC ./sink2.sh
   ```

3. **Detach from the `tmux` session** by pressing `Ctrl+b` then `d`.

4. **To reattach to the `tmux` session** later, use:

   ```sh
   tmux attach -t socat_server
   ```

### 3. Using `nohup`

`nohup` allows you to run commands that persist even after you log out.


1. **Run the `socat` command with `nohup`**:

   ```sh
   nohup socat -u TCP4-LISTEN:4444,reuseaddr,fork EXEC ./sink2.sh &
   ```

2. **Check the output** in `nohup.out` or redirect it to a file:

   ```sh
   nohup socat -u TCP4-LISTEN:4444,reuseaddr,fork EXEC ./sink2.sh > socat.log 2>&1 &
   ```

### 4. Using Systemd (for a more robust solution)

Creating a `systemd` service ensures that `socat` restarts automatically if it stops and starts on boot.

1. **Create a systemd service file** (e.g., `/etc/systemd/system/socat.service`):

   ```ini
   [Unit]
   Description=Socat TCP server

   [Service]
   ExecStart=/usr/bin/socat -u TCP4-LISTEN:4444,reuseaddr,fork EXEC ./sink2.sh
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

2. **Reload systemd configuration**:

   ```sh
   sudo systemctl daemon-reload
   ```

3. **Start the service**:

   ```sh
   sudo systemctl start socat.service
   ```

4. **Enable the service to start on boot**:

   ```sh
   sudo systemctl enable socat.service
   ```