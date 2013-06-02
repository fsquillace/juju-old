# JuJu
**JuJu**: the universal GNU/Linux package manager.

## Description
**JuJu** is a package manager that can be used for every GNU/Linux distribution.
JuJu is able to get the packages from the ArchLinux Official and AUR repositories and install them
directly in your home directory (by default is ~/.juju/).
You can choose to install the package using the pre-compiled or from the source code. The available 
pre-compiled packages are available for the architectures i686 and x86\_64 (in the future also armv{5,6,7} for your raspberry pi ;) ).
JuJu was designed to be really a lightweight program written completely in bash in order to get compatibility for many systems.

There are several reasons to use JuJu instead of a traditional package manager.
I just want to mention few of them:

1. Consider to have a server in production which run an important service. Generally,
    the system has to be as simple as possible without installing packages for administration purpose.
    With JuJu you can install your package in your own folder directory without affecting the performance of your
    system.
2. You can create your own GNU/Linux distribution from scratch. You can follow the Linux from Scratch guide
    (http://www.linuxfromscratch.org/lfs/) and install each packages mentioned into the guide using JuJu.
3. JuJu is a weak dependency package manager that allow the user to choose if the package dependencies need to be installed.

## Quickstart
After installing JuJu (See next section) install/remove a package like `tcpdump` is extremely easy.
Type the following:

    $> # To install tcpdump
    $> juju -i tcpdump
    $> # To install tcpdump starting from the source code
    $> juju -i -s tcpdump
    $> # For removing completely tcpdump from JuJu
    $> juju -r tcpdump
    $> # Find out more options by typing
    $> juju --help
    $> # Execute your program
    $> sudo tcpdump -i wlan0 'tcp and dst port 80'
    $> man tcpdump

Wowww!

For the moment it is not implemented the functionality for searching packages. Anyway, you can search for
packages going directly to the ArchLinux website Official https://www.archlinux.org/packages/ and AUR
https://aur.archlinux.org/ repositories.

## Installation
    $> # Clone JuJu in ~/.jujup directory
    $> git clone git://github.com/fsquillace/juju ~/.jujup
    $> # Source jujuenv or place the following line in your .bashrc file
    $> source ~/.jujup/lib/juju/jujuenv

The 'jujuenv' file is used to get update most of the environment variables such as PATH, LD\_LIBRARY\_PATH,
    MANPATH, etc.

## Advanced use
If you want to place the packages in another the folder destination different from the default one (~/.juju),
   type the following:

    $> JUJU_PACKAGE_HOME=<new_destination_folder> juju -i <package_name>

When JuJu install a package it first creates a temporary directory in /tmp/juju.XXXXXX for buiding the package.
After installing the package the temporary directory is removed. If you want to keep the temporary directory for debugging
purposes just type:

    $> JUJU_DEBUG=1 juju -i <package_name>

## License
Copyright (c) 2012-2013

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU Library General Public License as published
by the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Author
Filippo Squillace <feel.squally@gmail.com>

## WWW
https://github.com/fsquillace/juju
