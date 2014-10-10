#!/usr/bin/env bash
#
# This file is part of JuJu: The universal GNU/Linux package manager
#
# Copyright (c) 2012-2013 Filippo Squillace <feel.squally@gmail.com>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# References:
# https://wiki.archlinux.org/index.php/PKGBUILD
# https://wiki.archlinux.org/index.php/Creating_Packages

set -e

FILE="$(readlink -f ${BASH_ARGV[0]})"

################################ IMPORTS #################################
# Define the variables for the dependency commands bash, wget, tar, which, awk, grep, xz, file
WGET=wget
TAR=tar
source "$(dirname ${BASH_ARGV[0]})/util.sh"

################################# VARIABLES ##############################
FILIX_REPO=https://github.com/fsquillace/filix-repo/raw/master/package-groups
[ -z $JUJU_PACKAGE_HOME ] && JUJU_PACKAGE_HOME=~/.juju

################################# MAIN FUNCTIONS ##############################

function install_package_group_from_file(){
    # Install a package group in $JUJU_PACKAGE_HOME
    #
    # $1: pkggrpname (mandatory): str - Package group file name

    # Create the dirs
    mkdir -p $JUJU_PACKAGE_HOME/root
    mkdir -p $JUJU_PACKAGE_HOME/metadata/packages

    # Store the original working directory
    local origin_wd=$(pwd)

    pkggrpname=$1
    if [ -e "$pkggrpname" ]
    then
        echoerr -e "\033[1;31mError: Package group file does not exist\033[0m"
    fi

    # use mktemp, a non portable way is: $(mktemp --tmpdir=/tmp -d juju.XXXXXXXXXX)
    maindir=$(TMPDIR=/tmp mktemp -d -t juju.XXXXXXXXXX)

    builtin cd ${maindir}
    $TAR -zxvpf ${origin_wd}/${pkggrpname}

    echo -e "\033[1;37mInstalling ${pkggrpname}...\033[0m"
    ls ${maindir}/packages | xargs -I {} bash -c "cp -f -v -a ${maindir}/packages/{}/* $JUJU_PACKAGE_HOME/root"
    cp -f -a $maindir/metadata/* $JUJU_PACKAGE_HOME/metadata/
    echo -e "\033[1;37m$pkggrpname installed successfully\033[0m"

    builtin cd $origin_wd

    return 0
}


function install_package_group_from_repo(){
    # Download and install a package group in $JUJU_PACKAGE_HOME
    #
    # $1: pkggrp (mandatory): str -name of the package group

    # Create the dirs
    mkdir -p $JUJU_PACKAGE_HOME/root
    mkdir -p $JUJU_PACKAGE_HOME/metadata/packages

    # Store the original working directory
    local origin_wd=$(pwd)

    pkggrp=$1
    if [ -z "$pkggrp" ]
    then
        echoerr -e "\033[1;31mError: Package group name not specified\033[0m"
    fi

    # use mktemp, a non portable way is: $(mktemp --tmpdir=/tmp -d juju.XXXXXXXXXX)
    maindir=$(TMPDIR=/tmp mktemp -d -t juju.XXXXXXXXXX)

    builtin cd ${maindir}
    $WGET ${FILIX_REPO}/$(uname -m)/${pkggrp}.tar.gz
    $TAR -zxvf ${pkggrp}.tar.gz

    echo -e "\033[1;37mInstalling ${pkggrp}...\033[0m"
    ls ${maindir}/packages | xargs -I {} bash -c "cp -f -v -a ${maindir}/packages/{}/* $JUJU_PACKAGE_HOME/root"
    cp -f -a $maindir/metadata/* $JUJU_PACKAGE_HOME/metadata/
    echo -e "\033[1;37m$pkggrp installed successfully\033[0m"

    builtin cd $origin_wd

    return 0
}

