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

    local comm=$($WHICH $1 2> /dev/null )
    if [ "$comm" == "" ]
    then
        echo -e "\033[1;31mError: '$comm' command not found. Try execute: jujubox\033[0m" 1>&2;
        exit 128
    fi
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
