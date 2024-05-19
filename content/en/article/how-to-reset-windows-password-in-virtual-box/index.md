---
title: "How to reset Windows password in VirtualBox"
description: "This posts describes how to reset Windows password of Windows running inside VirtualBox"
date: 2024-05-19T02:58:40.873Z
draft: false
categories: [Computers]
tags: [windows,virtual box,password reset]
thumbnail: "/article/how-to-reset-windows-password-in-virtual-box/thumb.png"
---

If you forgot your password for Windows running inside VirtualBOx, the solution is very simple. Here we desribe the steps to reset the password.

We use VirtualBox Version 7.0.8 r156879 (Qt5.12.8) on Linux Mint 20.3 (Una) (Ubunti Codename=focal).
The Windows running in VirtualBox is [Windows 11](https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/) with standard user `User` for which `Passw0rd!` password was expired, then changed to something and this something was forgotten:

|Windows requires password|
|--|
|![forgotten_password](/article/how-to-reset-windows-password-in-virtual-box/forgotten.png)|

**Note**: It seems MS removed passwords for the Vms at the time of writing this post (19 May 2024).


### Hiren's BootCD

[Hirens BootCD](https://www.hirensbootcd.org/download/) contains NtPwdEdit utility which allows seemless password reset:

![ntpwedit](/article/how-to-reset-windows-password-in-virtual-box/ntpwedit.png)

We want to download it, mount under Windows VM and run it. It will see the Windows disk partitions in VirtualBox. Then we can 
run NtPwdEdit to reset the password. Also, we can access any data on windows partitions, edit windows registry, repair the system, etc. 
All the utilities which enable this are included on the disk.

## Mounting Hiren's BootCD on Windows VM

In machine `Settings` add optical disk and mount on it hirens cd:

|Mounting Hirens CD|
|--|
|![cd mount 1](/article/how-to-reset-windows-password-in-virtual-box/cdmount.png)|
|![cd mount 2](/article/how-to-reset-windows-password-in-virtual-box/cdmount2.png)|
|![cd mount 3](/article/how-to-reset-windows-password-in-virtual-box/cdmount3.png)|

## Booting VM from the CD

Run Windows VM and press F12 several times to get into the windows boot menu and choose UEFI CD to boot from:

|Booting from CD|
|----|
|![windows boot menu1](/article/how-to-reset-windows-password-in-virtual-box/winbootmenu.png)|
|![windows boot menu2](/article/how-to-reset-windows-password-in-virtual-box/winbootmenu2.png)|
|![windows boot menu3](/article/how-to-reset-windows-password-in-virtual-box/winbootmenu3.png)|

It should boot into Hirens Windows system:

![inside hirens windows](/article/how-to-reset-windows-password-in-virtual-box/inhirens.png)

## Resetting password

Ok, we are almost done. Go to `Utilites`=>`Security`=>`NtPasswordEdit`:

![choose utility](/article/how-to-reset-windows-password-in-virtual-box/chooseutil.png)

And now we can reset password for any user:

![ntpwedit](/article/how-to-reset-windows-password-in-virtual-box/ntpwedit.png)

❗Don't forget to click on `OPEN` button to get the list of users. 

If for any reson, the password cannot be reset by `NtPasswordEdit`, you can try to use Lazesoft utility:

![lazesoft](/article/how-to-reset-windows-password-in-virtual-box/lazesoft.png)

Good Luck!
