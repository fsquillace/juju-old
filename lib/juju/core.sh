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

#set -e

FILE="$(readlink -f ${BASH_ARGV[0]})"

################################ IMPORTS #################################
# Define the variables for the dependency commands bash, wget, tar, which, awk, grep, xz, file
WGET=wget
TAR=tar
source "$(dirname ${BASH_ARGV[0]})/util.sh"

################################# VARIABLES ##############################
JUJU_REPO=https://github.com/fsquillace/juju-repo/raw/master/package-groups
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
    if [ ! -e $pkggrpname ]
    then
        die "Error: Package group file ${pkggrpname} does not exist"
    fi

    # use mktemp, a non portable way is: $(mktemp --tmpdir=/tmp -d juju.XXXXXXXXXX)
    maindir=$(TMPDIR=/tmp mktemp -d -t juju.XXXXXXXXXX)
    trap - QUIT EXIT ABRT KILL TERM INT
    trap "cleanup_build_directory ${maindir}; die \"Error occurred when installing $pkggrpname\"" EXIT QUIT ABRT KILL TERM INT

    builtin cd ${maindir}
    $TAR -zxpf ${origin_wd}/${pkggrpname}

    info "Installing ${pkggrpname}..."
    ls ${maindir}/packages | xargs -I {} bash -c "cp -f -a ${maindir}/packages/{}/* $JUJU_PACKAGE_HOME/root"
    cp -f -a $maindir/metadata/* $JUJU_PACKAGE_HOME/metadata/
    info "$pkggrpname installed successfully"

    builtin cd $origin_wd
    trap - QUIT EXIT ABRT KILL TERM INT
    cleanup_build_directory ${maindir}

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
        die "Error: Package group name not specified"
    fi

    # use mktemp, a non portable way is: $(mktemp --tmpdir=/tmp -d juju.XXXXXXXXXX)
    maindir=$(TMPDIR=/tmp mktemp -d -t juju.XXXXXXXXXX)
    trap - QUIT EXIT ABRT KILL TERM INT
    trap "cleanup_build_directory ${maindir}; die \"Error occurred when installing $pkggrp\"" EXIT QUIT ABRT KILL TERM INT

    builtin cd ${maindir}
    $WGET ${JUJU_REPO}/$(uname -m)/${pkggrp}.tar.gz
    $TAR -zxpf ${pkggrp}.tar.gz

    info "Installing ${pkggrp}..."
    ls ${maindir}/packages | xargs -I {} bash -c "cp -f -a ${maindir}/packages/{}/* $JUJU_PACKAGE_HOME/root"
    cp -f -a $maindir/metadata/* $JUJU_PACKAGE_HOME/metadata/
    info "$pkggrp installed successfully"

    builtin cd $origin_wd
    trap - QUIT EXIT ABRT KILL TERM INT
    cleanup_build_directory ${maindir}

    return 0
}


function normalize_package(){
    [ "$1" == "sh" ] && echo "bash" && return
    [ "$1" == "libusbx" ] && echo "libusb" && return
    [ "$1" == "awk" ] && echo "gawk" && return
    echo $1 | sed -e 's/>=.*//' -e 's/>.*//' \
        -e 's/<=.*//' -e 's/<.*//' \
        -e 's/==.*//'
}

function suppress_duplicates(){
    echo "${@}" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

function get_closure_dependencies(){
    # Calculate the closure dependencies of a package
    #
    # $1: pkgname (mandatory): str -name of the package

    pkgname=$1
    if [ -z "$pkgname" ]
    then
        die "Error: Package name not specified"
    fi
    normalized_pkgname=$(normalize_package $pkgname)

    out=$(pacman -Qi $normalized_pkgname | grep "Depends On" | sed 's/Depends On.* ://')
    deps=($out)
    if [ "${deps[0]}" == "None" ] || [ "${deps}" == "" ]
    then
        echo $normalized_pkgname
        return
    fi

    tot_deps=()
    for dep in ${deps[@]}
    do
        new_deps=$(get_closure_dependencies $dep)
        tot_deps=($(suppress_duplicates ${tot_deps[@]} ${new_deps[@]}))
    done
    echo $normalized_pkgname ${tot_deps[@]}
}


function generate_package_group(){
    # Generate a package group from a package name
    #
    # $@: pkgname(s) (mandatory): str - Target package names

    # Store the original working directory
    local origin_wd=$(pwd)

    if [ -z "$1" ]
    then
        die "Error: Package name not specified"
    fi

    # use mktemp, a non portable way is: $(mktemp --tmpdir=/tmp -d juju.XXXXXXXXXX)
    maindir=$(TMPDIR=/tmp mktemp -d -t juju.XXXXXXXXXX)
    trap - QUIT EXIT ABRT KILL TERM INT
    trap "cleanup_build_directory ${maindir}; die \"Error occurred during generation of package group\"" EXIT QUIT ABRT KILL TERM INT
    mkdir -p ${maindir}/packages
    mkdir -p ${maindir}/metadata
    builtin cd ${maindir}/packages

    for pkgname in $@
    do
        if [ -d "$pkgname" ]
        then
            info "Skipping ${pkgname} since it was already built from previous dependencies."
            continue
        fi

        info "Calculating the closure dependencies for ${pkgname}..."
        deps=$(get_closure_dependencies $pkgname)
        info "List of closure dependencies:"
        echo $deps
        info "Copying the dependencies..."
        for dep in $deps
        do
            [ -d "$dep" ] && continue
            mkdir -p $dep
            pacman -Ql $dep | grep -v "/$" | sed 's/.* //' | xargs -I {} bash -c "[ -f {} ] && cp -f --parents {} $dep"
        done

        if [ -e "${pkgname}/usr/bin" ]
        then
            mkdir -p ld
            for executable in $(ls ${pkgname}/usr/bin/*)
            do
                info "Copying the dynamic libraries for ${executable}..."
                for lib in $( ldd ${executable} | grep -v dynamic | grep "=>" | awk '{print $3}' )
                do
                    [ -e $lib ] && cp -f --parents $lib ld
                done
                for lib in $( ldd ${executable} | grep -v dynamic | grep -v "=>" | awk '{print $1}' )
                do
                    [ -e $lib ] && cp -f --parents $lib ld
                done

                # ARCH amd64
                if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
                    cp -f --parents /lib64/ld-linux-x86-64.so.2 ld
                fi

                # ARCH i386
                if [ -f  /lib/ld-linux.so.2 ]; then
                    cp -f --parents /lib/ld-linux.so.2 ld
                fi
            done
        fi

    done
    info "Generating the compressed file ${1}.tar.gz..."
    $TAR -zcpf ${origin_wd}/${1}.tar.gz -C ${maindir} packages

    info "Package group generated successfully"

    builtin cd $origin_wd
    trap - QUIT EXIT ABRT KILL TERM INT
    cleanup_build_directory ${maindir}

    return 0
}


function cleanup_build_directory(){
# $1: maindir (optional) - str: build directory to get rid

    local maindir=""
    [ -n  "$1" ] && maindir=$1

    if [ "$maindir" != "" ]; then
        rm -fr "$maindir"
    fi
}
