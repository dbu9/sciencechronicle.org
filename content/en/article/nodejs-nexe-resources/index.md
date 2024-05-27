---
title: "NodeJS nexe resources"
description: "Add resources to nexe-created executable file and access them from inside the executable: some insights"
date: 2024-05-27T01:58:40.873Z
draft: false
tags: [nodejs, nexe, nexe-cli, resources]
categories: [computers, nodejs]
thumbnail: "/article/nodejs-nexe-resources/thumb.png"
---

For some reason, there is a scare description of how to add and access resources for executables created by nexe-cli. Here we make some clarifications.

## What's nexe-cli?

[nexe-cli](https://github.com/nexe/nexe) is an utility which creates a standalone executable from nodejs code. It compiles nodejs runtime for the target platform and creates a stanalone 
executable which contains the nodejs runtime and program js source code. Note, however, that nexe does not include node_modules folder in the executable so if the source code uses some of npm modules the distributed executable should be distributed along with the modules:

```bash
ls ./myexeproject
node_modules
myprogram.exe
```

## Adding resources

nexe allows adding any kind of file as a resource to the executable file. Let's see a concrete examlple:

```bash
tree ./myproject

.
├── build
│   ├── main.js
│   └── myprogram.exe
├── package.json
├── package-lock.json
├── resources
│   ├── rar
│   └── unrar.sh
├── src
│   └── main.ts
└── tsconfig.json
```

This is a typescript project which is compiled with `tsc` outputting the result into `build/main.js`. Then we create an executable with 

```bash
nexe --build -i build/main.js -o build/myprogram.exe
```

We want to add two files to the executable, `unrar.sh` which is textual bash script and `rar` which is executable linux binary. 
We do this with:

```bash
nexe --build -r resources/**/* -i build/main.js -o build/myprogram.exe
```

## Accessing the resources

The resources can be accessed by `fs.readFile()` or `fs.readFileAsync()` functions. Let's read `unrar.sh`:

```ts
import fs from "fs"
import {exec} from "node:child_process"
import util from "node:util"
import path from "node:path"
async function main() {
	const scriptPath = path.join('resources', 'unrar.sh')
	console.log(`scriptPath: ${scriptPath}`)
	const scriptContent = fs.readFileSync(scriptPath, {encoding: "utf8"})
	console.log(scriptContent)
}

main()
```

To make sure our executable does not refer to original `resources` folder, we move it to some unrelated folder, `~/Downloads` in this test. 
We run the program:

```bash
~/Downloads/myprogram.exe
scriptPath: resources/unrar.sh
#!/bin/bash
echo "Hello"
```

This is the text of the bash script.

Can we run executable directly from the our executable file? Let's try:


```ts
import fs from "fs"
import {exec} from "node:child_process"
import util from "node:util"
import path from "node:path"
const execPromisified = util.promisify(exec);

async function main() {
	console.log(process.argv[2])
	const fileName = process.argv[2]
	const rarPath = path.join('resources', 'rar')
	const withArgs = `${rarPath} a x.rar ${fileName}`
	console.log(`rarPath: ${rarPath}`)
	const result = await execPromisified(withArgs)
	console.log(result.stdout)
}

main()
```

The code above tries to execute `rar` located at `rosources` folder inside executable. `rar` is run with command `a x.rar` which creates an archive `x.rar` from a file supplied as a cmd line argument. 

Let's try to compress some file in `~/Download` folder, for example `myprogram.exe` itself:

```bash
cd ~/Downloads
./myprogram myprogram.exe
```

and we get the following error:

```bash
./myprogram.exe myprogram.exe 
myprogram.exe
rarPath: resources/rar
node:internal/errors:932
  const err = new Error(message);
              ^

Error: Command failed: resources/rar a x.rar myprogram.exe
/bin/sh: 1: resources/rar: not found

    at ChildProcess.exithandler (node:child_process:422:12)
    at ChildProcess.emit (node:events:518:28)
    at maybeClose (node:internal/child_process:1105:16)
    at Socket.<anonymous> (node:internal/child_process:457:11)
    at Socket.emit (node:events:518:28)
    at Pipe.<anonymous> (node:net:337:12) {
  code: 127,
  killed: false,
  signal: null,
  cmd: 'resources/rar a x.rar myprogram.exe',
  stdout: '',
  stderr: '/bin/sh: 1: resources/rar: not found\n'
}

Node.js v20.11.0
```

What happens here is that `exec` looks for `rar` in `~/Downloads/resources`. Try to put `resources/rar` into `~/Downloads` and all works without errors.

So, our conclusion is that `exec()` function does not know about the internal resources of our executable.

What we can do is to access the `resources` folder with `fs.readFile()` or `fs.readFileSync()` as mentioned by nexe documentation but not in very detailed way. That's why we wrote that post.

```ts
import fs from "fs"
import {exec} from "node:child_process"
import util from "node:util"
import path from "node:path"

const execPromisified = util.promisify(exec);
async function main() {
	const rarPath = path.join('resources', 'rar')
	console.log(`rarPath: ${rarPath}`)
	const rarFile = fs.readFileSync(rarPath)
	fs.writeFileSync("myrar", rarFile)
	console.log(`__dirname value: ${__dirname}`)
	console.log(`process cwd: ${process.cwd()}`)
	const fileName = process.argv[2]
	const result = await execPromisified(`echo $(pwd); chmod +x myrar && ./myrar a x.rar ${fileName}`)
	console.log(result.stdout)
}

main()
```

In the code above, which is run once again in `~/Downloads` directory, we read our `rar` file from the resource directory and write it as `myrar` file in `~/Downloads`. We run the program:

```bash
cd ~/Downloads
./myprogram.exe myprogram.exe
```

which outputs:

```bash
rarPath: resources/rar
__dirname value: /home/user/Downloads/build
process cwd: /home/user/Downloads
/home/user/Downloads

RAR 7.01   Copyright (c) 1993-2024 Alexander Roshal   12 May 2024
Trial version             Type 'rar -?' for help

Evaluation copy. Please register.

Creating archive x.rar

Adding    myprpgram.exe                                                       OK 
Done
```

We succeeded. And we have some interesing observations.

`process.cwd()` reported executable current working directory is `~/Downloads`. The same was reported by `echo $(pwd)` run by `exec()`. However, `__dirname` remembers the part of the path executable was created in, so it displays `${process.cwd()}/build`.

## Conclusion

To access resources in executable, use `fs.readFile()` or `fs.readFileAsync()` and write them to the disk if you want other functions like `exec()` to use them.