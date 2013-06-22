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

# This module requires:
# JUJU_PACKAGE_HOME (mandatory) to check if the executable are available
# PATH (optional) in order to set new paths of executables

# List of Unix commands provided:
# AWK (mandatory)
# BASH (mandatory)
# WGET (mandatory)
# GREP (mandatory)
# TAR (mandatory)
# FILEE (mandatory)
# XZ (optional): it is useful for getting the precompiled.
#                A warn will be print if xz doesn't work.

########################### MAIN VARIABLES ENVIRONMENT #################################

[ -z "$JUJU_PACKAGE_HOME" ] && JUJU_PACKAGE_HOME="$HOME/.juju"
JUJU_PACKAGE_HOME=$(readlink -f $JUJU_PACKAGE_HOME)
mkdir -p $JUJU_PACKAGE_HOME

[ -z $JUJU_DEBUG ] && JUJU_DEBUG=0

# Update PATH with the juju local repo
# Search for the commands juju dependencies in this order: root system, juju local repo
export PATH=$PATH:${HOME}/.jujup/bin:$JUJU_PACKAGE_HOME/root/usr/local/bin:$JUJU_PACKAGE_HOME/root/usr/bin:$JUJU_PACKAGE_HOME/root/bin:$JUJU_PACKAGE_HOME/root/usr/local/sbin:$JUJU_PACKAGE_HOME/root/usr/sbin:$JUJU_PACKAGE_HOME/root/sbin

######################## VARIABLES ENVIRONMENT FOR COMPILING #########################
export CPATH=$JUJU_PACKAGE_HOME/root/usr/include
export C_INCLUDE_PATH=$JUJU_PACKAGE_HOME/root/usr/include
export CPLUS_INCLUDE_PATH=$JUJU_PACKAGE_HOME/root/usr/include


######################## MAIN COMMANDS #################################

function get_loader(){
    # Get the glibc version installed
    if [ ! -f "$JUJU_PACKAGE_HOME/metadata/packages/glibc/PKGBUILD" ]
    then
        echo -e "\033[1;31mError: The executable in JuJu repo cannot be executed without glibc. Install it first: juju -i glibc\033[0m" 1>&2;
        exit 128
    fi

    if [ ! -f $JUJU_PACKAGE_HOME/root/usr/lib/ld-*.so ]; then
        echo -e "\033[1;31mError: The executable in JuJu repo cannot be executed without glibc. Install it first: juju -i glibc\033[0m" 1>&2;
        exit 128
    fi
    echo $JUJU_PACKAGE_HOME/root/usr/lib/ld-*.so --library-path "$JUJU_PACKAGE_HOME/root/lib:$JUJU_PACKAGE_HOME/root/usr/lib"
}

WHICH=which
if ! $WHICH --help &> /dev/null
then
    echo -e "\033[1;31mError: 'which' command not found. Try execute: jujubox\033[0m" 1>&2;
    exit 128
fi
WHICH=$($WHICH $WHICH)
if [[ $WHICH =~ $JUJU_PACKAGE_HOME ]]; then
    WHICH="$(get_loader) $WHICH"
fi

function _find_command(){
# $1: initial command

    local comm=$($WHICH $1)
    if [ "$comm" == "" ]
    then
        echo -e "\033[1;31mError: '$1' command not found. Try execute jujubox or compile package\033[0m" 1>&2;
        exit 128
    fi
    # TODO not necessarily true that the executable inside juju has to have a customize loader
    if [[ $comm =~ $JUJU_PACKAGE_HOME ]]; then
        echo "$(get_loader) $comm"
    else
        echo "$comm"
    fi
}

GREP=$(_find_command "grep")

BASHH=$(_find_command "bash")

TAR=$(_find_command "tar")

AWK=$(_find_command "awk")

XZ=$(_find_command "xz")

WGET=$(_find_command "wget")

FILEE=$(_find_command "file")


# Tests of all commands
function test_command(){
if ! $1 --help 1> /dev/null
then
    echo -e "\033[1;31mError: '$1' not working. Try execute jujubox or compile package.\033[0m" 1>&2;
    exit 1
fi
}

test_command "$GREP"
test_command "$BASHH"
test_command "$TAR"
test_command "$AWK"
test_command "$FILEE"
test_command "$WGET"

if ! $XZ --help 1> /dev/null
then
    echo -e "\033[1;33mWarning: '$XZ' not working. It will not be possible to get pre-compiled packages. Try execute jujubox or compile package. Continuing anyway...\033[0m" 1>&2;
fi

if ! $WGET --help | $GREP "no-check-certificate" 1> /dev/null
then
    echo -e "\033[1;31mError: '$WGET' not working properly. Try execute jujubox or compile package.\033[0m" 1>&2;
    exit 1
fi
