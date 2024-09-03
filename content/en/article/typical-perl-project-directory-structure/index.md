---
title: "A typical Perl project directory structure"
description: "This article describes a typical Perl project directory structure and purposes of each component."
date: 2024-09-01T01:58:40.873Z
draft: false
tags: [perl]
categories: [computers, linux]
thumbnail: "/article/typical-perl-project-directory-structure/thumb.png"
---

A typical Perl project directory structure is designed to separate the main script(s) from modules, configurations, and other resources like tests or documentation. Here’s an example of a standard Perl project directory structure:

```
my_perl_project/
├── bin/
│   └── main.pl
├── lib/
│   ├── MyApp/
│   │   ├── Module1.pm
│   │   └── Module2.pm
├── t/
│   ├── 01_module1.t
│   └── 02_module2.t
├── script/
│   └── some_utility_script.pl
├── doc/
│   └── README.md
├── Makefile.PL
└── MANIFEST
```

### Breakdown of the Structure

#### 1. **`bin/` Directory:**
   - **Purpose:** This directory contains the main executable scripts of your application.
   - **Example:** `main.pl` is the main entry point for your application.
   - **Content:**
     - `main.pl`: The main script that uses the modules from the `lib/` directory.

#### 2. **`lib/` Directory:**
   - **Purpose:** This directory is where your Perl modules (libraries) reside.
   - **Example:** The `MyApp/` directory within `lib/` contains the modules `Module1.pm` and `Module2.pm`.
   - **Content:**
     - `MyApp/Module1.pm`: A Perl module providing specific functionality.
     - `MyApp/Module2.pm`: Another Perl module.

   **Typical Module Structure:**
   ```perl
   # lib/MyApp/Module1.pm
   package MyApp::Module1;

   use strict;
   use warnings;

   sub new {
       my $class = shift;
       return bless {}, $class;
   }

   sub do_something {
       print "Doing something...\n";
   }

   1;
   ```

#### 3. **`t/` Directory:**
   - **Purpose:** This directory contains test files for your modules. The `t/` directory is a convention in Perl projects for storing tests.
   - **Example:** `01_module1.t` might contain tests for `Module1.pm`, and `02_module2.t` for `Module2.pm`.
   - **Content:**
     - `01_module1.t`: Test script for `Module1.pm`.
     - `02_module2.t`: Test script for `Module2.pm`.

   **Typical Test Structure:**
   ```perl
   # t/01_module1.t
   use strict;
   use warnings;
   use Test::More tests => 1;
   use MyApp::Module1;

   my $module = MyApp::Module1->new();
   isa_ok($module, 'MyApp::Module1');
   ```

#### 4. **`script/` Directory:**
   - **Purpose:** This directory is often used for utility scripts related to your project. These might include installation scripts, migration scripts, or other utilities.
   - **Example:** `some_utility_script.pl` might be a script used to perform a specific task, like setting up the environment.

#### 5. **`doc/` Directory:**
   - **Purpose:** Documentation for the project, such as README files, user guides, or API documentation.
   - **Example:** `README.md` provides an overview of the project and instructions on how to use or install it.

#### 6. **`Makefile.PL`:**
   - **Purpose:** This file is used to generate a Makefile for building and installing your Perl module. It's typically used with `ExtUtils::MakeMaker` or `Module::Build`.
   - **Content:** Describes the project and its dependencies.
   - **Example:**
     ```perl
     # Makefile.PL
     use ExtUtils::MakeMaker;

     WriteMakefile(
         NAME         => 'MyApp',
         VERSION_FROM => 'lib/MyApp/Module1.pm', # finds $VERSION
         PREREQ_PM    => {
             'Test::More' => 0,
         },
         LIBS         => ['-lm'],    # e.g., '-lm'
         DEFINE       => '',         # e.g., '-DHAVE_SOMETHING'
         INC          => '-I.',      # e.g., '-I. -I/usr/include/other'
         dist         => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
     );
     ```

#### 7. **`MANIFEST`:**
   - **Purpose:** A list of all the files in your project, often used in conjunction with the distribution and packaging of the project.
   - **Content:** Lists each file and directory in the project.

   **Example:**
   ```plaintext
   bin/main.pl
   lib/MyApp/Module1.pm
   lib/MyApp/Module2.pm
   t/01_module1.t
   t/02_module2.t
   Makefile.PL
   MANIFEST
   ```

### Usage
- **Running the Application:** Navigate to the `bin/` directory and run `main.pl`.
- **Using Modules:** In `main.pl`, you can use modules from `lib/` like so:
  ```perl
  use lib '../lib';
  use MyApp::Module1;

  my $module = MyApp::Module1->new();
  $module->do_something();
  ```
- **Running Tests:** Run tests using `prove` or `perl`:
  ```bash
  prove -l t/
  ```

### Summary
This directory structure provides a clean and organized way to manage Perl projects, separating the main script, modules, tests, and other resources. It follows common conventions used in the Perl community and makes it easier to maintain and scale your project.