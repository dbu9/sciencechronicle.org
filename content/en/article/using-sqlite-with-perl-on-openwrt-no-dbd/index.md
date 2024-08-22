---
title: "Using SQLITE database with Perl on OpenWRT"
description: "This article discusses using an SQLite database with Perl on the OpenWRT."
date: 2024-08-21T03:58:40.873Z
draft: false
categories: [Computers, Linux]
tags: [openwrt, perl, dbd, dbi, sqlite, database is locked (6), busy_timeout]
thumbnail: "/article/using-sqlite-with-perl-on-openwrt-no-dbd/thumb.png"
---

This article discusses using an SQLite database with Perl on the OpenWRT `openwrt-23.05 branch (git-23.233.52805-dae2684)`. We aim to use an SQLite database with Perl. 

First, we need to install the `DBI` module and then find and install `DBD` for SQLite. Let's examine the directory of Perl modules available on OpenWRT: [Perl Modules on OpenWRT](https://openwrt.org/packages/index/languages---perl).

One can see that the `DBI` module is present: [perl-dbi](https://openwrt.org/packages/pkgdata/perl-dbi). After installing it, let's check which `DBD` modules are included:

Let's find the Perl installation path:

```bash
perl -MDBI -e 'print $INC{"DBI.pm"}, "\n";'
/usr/lib/perl5/5.28/DBI.pm
```

Next, we look for `DBD` modules:

```bash
ls /usr/lib/perl5/5.28/DBD
DBM.pm       ExampleP.pm  File.pm      Gofer        Gofer.pm     Mem.pm       NullP.pm     Proxy.pm     Sponge.pm
```

Unfortunately, we don't have the SQLite `DBD` module. Additionally, we cannot find any precompiled package named "perl-dbd-sqlite" in the package list.

One possible solution is to compile the module on the required architecture and copy it to OpenWRT. The architecture on OpenWRT is:

```bash
Linux OpenWrt 5.15.150 #0 SMP Fri Mar 22 22:09:42 2024 aarch64 GNU/Linux
```

We could do this with QEMU, but in this post, we chose another approach. We'll install `sqlite3-cli` and write a Perl wrapper around it.

### Install the Utility

First, install the utility:

```bash
opkg update 
opkg install sqlite3-cli
```

### Write the Wrapper

Next, we write a wrapper:

```perl
package My::Sqlite;

use strict;
use warnings;

use JSON::PP;
use Try::Tiny;

sub new {
  my ($class, $dbname) = @_;
  my $self = {};
  $self->{dbname} = $dbname;
  $self->{codec} = JSON::PP->new->pretty; 
  bless $self, $class;  
  return $self;
}

sub exec {
  my ($self, $sql) = @_;
  my $dbname = $self->{dbname};
  my $json = `sqlite3 -cmd ".timeout 1000" -json $dbname "$sql"`;
  my $h = [];
  if ($json ne "") {
    try {
      $h = $self->{codec}->decode($json);
    } 
    catch {
      $h = undef;
    };
  }
  return $h;
}

1;
```

Note that the module uses the `JSON::PP` and `Try::Tiny` modules, which are available in the Perl repository for OpenWRT.

We use the `-cmd` option for `sqlite3` to avoid the "database is locked (6)" error. By default, the timeout for `sqlite3` is 0. For more details, refer to the SQLite documentation: [busy_timeout](https://sqlite.org/c3ref/busy_timeout.html).

### Using the Module

Place the `Sqlite.pm` module into the `perllib/My` folder. To use the module:

```perl
use strict;
use warnings;

use lib "perllib";
use My::Sqlite;

my $db = My::Sqlite->new("test.db");
my $response1 = $db->exec("CREATE TABLE IF NOT EXISTS client(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)");
if (! defined $response1 ) {
  die "Error using DB";
}

my $response2 = $db->exec("INSERT INTO client(name) VALUES('John')");
if (! defined $response2 ) {
  die "Error using DB";
}

my $response3 = $db->exec("SELECT * FROM client");
if (! defined $response3 ) {
  die "Error using DB";
}

foreach my $row (@$response3) {
  print "id: ", $row->{id}, " name: ", $row->{name}, "\n";
}
```

Thus, with a simple wrapper, we can simplify our work without needing to compile `DBD` for the OpenWRT architecture. Happy coding!

---

This version should be clearer and more polished while maintaining all the technical details and code you provided.