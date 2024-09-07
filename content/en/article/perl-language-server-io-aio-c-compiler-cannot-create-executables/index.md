---
title: "Installing Perl::LanguageServer fails because IO:AIO error: c compiler cannot create executables"
description: "The blog article describes how to install Perl::LanguageServer on Linux Mint"
date: 2024-09-06T11:52:37.716Z
draft: false
tags: [perl]
categories: [Computer, Linux]
thumbnail: "/article/perl-language-server-io-aio-c-compiler-cannot-create-executables/thumb.png"
---

## The problem

While attempting to install `Perl::LanguageServer` on my **Linux Mint 20.3 Una**, the following command:

```bash
cpan install Perl::LanguageServer
```

failed, reporting that the `IO::AIO` dependency was unsatisfied.

I tried installing the `IO::AIO` module separately:

```bash
cpan install IO::AIO
```

However, this resulted in the following error:

```text
Continue anyways?  [y] y
checking for gcc... x86_64-linux-gnu-gcc
checking whether the C compiler works... no
configure: error: in `/home/morpher/.cpan/build/IO-AIO-4.81-7':
configure: error: C compiler cannot create executables
See `config.log` for more details
Warning: No success on command[/usr/bin/perl Makefile.PL INSTALLDIRS=site]
  MLEHMANN/IO-AIO-4.81.tar.gz
  /usr/bin/perl Makefile.PL INSTALLDIRS=site -- NOT OK
```

Next, I checked whether the required modules, as referred to by the [Perl-LanguageServer repository](https://github.com/richterger/Perl-LanguageServer), were installed by running:

```bash
sudo apt install libanyevent-perl libclass-refresh-perl libcompiler-lexer-perl \
libdata-dump-perl libio-aio-perl libjson-perl libmoose-perl libpadwalker-perl \
libscalar-list-utils-perl libcoro-perl
```

During this process, I discovered that the package `libcompiler-lexer-perl` could not be found. I removed that line and installed the remaining packages. Unfortunately, this didn't solve the issue.

I also tried:

```bash
sudo apt install libc6-dev
```

But it didn’t help either, as this package was already installed.

## The Solution

The real solution turned out to be much simpler:

```bash
sudo apt install libperl-dev
```

Installing `libperl-dev` successfully resolved the issue with the `IO::AIO` module installation.