---
title: "NodeJS / Typescript: module in directory"
description: "This article describes a popular approach to nodejs/typescript modularization by containing the modules into a directory."
date: 2024-05-27T11:52:37.716Z
draft: false
tags: [nodejs, code modularization, modules]
categories: [computers, nodejs, typescript]
thumbnail: "/article/nodejs-typescript-module-in-directory/thumb.png"
---

What are the hardest problems in software engineering? The obvious answer is "cache invalidation and variable naming." However, on a more serious note, a significant part of software engineering is devoted to the separation of concerns. This is one of the reasons object-oriented programming (OOP) came into existence. In fact, it could be argued that the entire field of software engineering revolves around the separation of concerns—how to effectively factor and modularize software to make it more manageable.

In this article, we focus on a very specific issue: the JavaScript (Node.js) and TypeScript approach to modularizing code. The thumb rules are: (a) create a directory for the module functions, (b) put every function that belongs to the module in a separate file, and (c) export functions that comprise the module interface in `index.js` (or `index.ts`).

Let's look at the following project:

```ts
// main.ts

import {Car, Bicycle} from "./transport"
function main() {
	const car = new Car()
	const bicycle = new Bicycle()
}
```

In the main function we import two classes, `Car` and `Bicycle` from the folder `./transport` which contains the code related to the transport functionality. What is very useful is that we define `index.ts` inside transport which defines what we want to export from the folder:

```ts
// index.ts
export {Car} from "./Car.ts"
export {Bicyle} from "./Bycicle.ts"
```

```ts
// Car class
import {helperFunction} from "./helperFunction.ts"
export class Car {
	// implementation
}
```

```ts
// Bicycle class
export class Bicycle {
	// implementation
}
```

```ts
export function helperFunction() {
	// implementation
}
```

The contents of the transport folder:

```bash
Car.ts
Bicycle.ts
helperFunction.ts
index.ts
```

The `transport` folder exports by means of `index.ts` two classes. The class `Car` imports `helperFunction()`,which is not exported by `index.ts`. But `helperFunction` and both classes are exported from the respective files, each of them. So we just could ignore the `index.ts` and import everything from the folder:

```ts
// main.ts
import {Car} from "./transport/Car.ts" // no error
import {Bicycle} from "./transport/Bicycle.ts" // no error
import {helperFunction} from "./transport/helperFunction.ts" // no error
```

Yes, type script does not prevent the above exports. The import/export system from the folder is a *convention*, not a mechanism encforced by typescript or javascript.
For us, as programmers, it's good to follow this convention: import only using the name of the folder, not below it.

If we try to import `helperFunction()` using the convntion, we could not do it:

```ts
import {helperFunction} from "./transport" // ERROR!
```

because the function is not exported. 

Happy coding!