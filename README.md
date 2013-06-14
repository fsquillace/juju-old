# JuJu
**JuJu**: the universal GNU/Linux package manager.

## Description
**JuJu** is a package manager that can be used for every GNU/Linux distribution.

JuJu is able to get the packages from the ArchLinux Official and AUR repositories and install them
inside your home directory (by default is ~/.juju/).

You can choose to install the package using either the pre-compiled packages or from the source code. The available
pre-compiled packages are for i686 and x86\_64 architectures (in the future also armv{5,6,7} for your raspberry pi ;) ).
JuJu was designed to be a lightweight program in order to get compatibility with many systems.
The list of the main dependencies are: 'bash>=4.0', 'wget' and 'tar'. That's it!

There are several reasons to use JuJu instead of a traditional package manager. I just want to mention few of them:

1. Consider to have a server in production which run an important service. Generally,
    it is better to keep the system in order to be as simple as possible without installing further packages as root.
    With JuJu you can install your packages inside your own home directory without affecting the performance or stability of your
    system.
2. You do not need to get root permissions for installing a package.
3. You can create your own GNU/Linux distribution from scratch. You can follow the Linux from Scratch guide
    (http://www.linuxfromscratch.org/lfs/) and install each packages mentioned into the guide using JuJu.
4. JuJu is a weak dependency package manager that allow the user to choose if the package dependencies need to be installed.
5. To get easily your vim plugins, python libraries and more for every host you are logged in.

## Quickstart
After installing JuJu (See next section) install/remove a package like `tcpdump` is extremely easy.

To install tcpdump:

    $> juju -i tcpdump

To install tcpdump starting from the source code:

    $> juju -i -s tcpdump

For listing the packages already installed:

    $> juju -l
    tcpdump

For listing the content of the package installed:

    $> juju -l tcpdump
    /usr/bin/tcpdump
    /usr/share/licenses/tcpdump/LICENSE
    ...

For removing completely tcpdump from JuJu:

    $> juju -r tcpdump

Find out more options by typing:

    $> juju --help

Execute your commands in two ways, wrapping the command with jujuenv:

    $> jujuenv tcpdump --help

Or setting the environment variables inside the shell by using 'source jujuenv' command:

    $> source jujuenv
    $> sudo tcpdump -i wlan0 'tcp and dst port 80'
    $> man tcpdump

Wowww!

The 'jujuenv' file is used to get updated most of the environment variables such as PATH, LD\_LIBRARY\_PATH,
    MANPATH, etc. It also update the variables PYTHONPATH and VIMRUNTIME to get easily installed your favourite python libraries and
    vim plugins.

For the moment it is not implemented the functionality for searching packages. Anyway, you can search for
packages going directly to the ArchLinux website Official https://www.archlinux.org/packages/ and AUR
https://aur.archlinux.org/ repositories.

## Installation
You can get JuJu from git or from the tarball.
If you want to get JuJu from git, clone JuJu in ~/.jujup directory:

    $> git clone git://github.com/fsquillace/juju ~/.jujup

Otherwise download the tarball:

    $> wget https://github.com/fsquillace/juju/archive/main.tar.gz
    $> tar xzvf main.tar.gz && mv juju-main/ ~/.jujup

Set the PATH variable in your shell (or in ~/.bashrc file):

    $> export PATH=$PATH:$HOME/.jujup/bin

## Advanced use
If you want to place the packages in a particular folder different from the default one (~/.juju),
   type the following:

    $> JUJU_PACKAGE_HOME=<new_destination_folder> juju -i <package_name>

When JuJu installs a package it first creates a temporary directory in /tmp/juju.XXXXXX for buiding the package.
After installing the package the temporary directory is automatically removed. If you want to keep the temporary directory for debugging
purposes just type:

    $> JUJU_DEBUG=1 juju -i <package_name>

### JuJu dependencies
Apart the main dependencies (bash, tar and wget), Juju has few other dependencies that can be fixed
through the jujubox. jujubox is a minimal script that retrieves a tarball of a package set (awk, grep and xz)
that will be installed into the juju repo local from a remote repository.
Usually these dependencies are available in many \*nix systems. However, in case
your system does not have one of these dependencies you can get it by typing:

    $> jujubox

## Troubleshooting

1. Why don't I see the command if I use sudo?

TODO ANSWER

2. I have installed a python library (or vim plugin) but the system doesn't see it. It says "no module named 'modulename'".

This is because JuJu need to update the 'PYTHONPATH' or the vim runtimepath with the new directories created after the
installation of the package.
To get it updated just re-source jujuenv:

    $> source ~/.jujup/lib/juju/jujuenv

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
