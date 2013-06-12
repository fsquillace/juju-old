#!/bin/bash
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

# Import util.sh first
source "$(dirname ${BASH_ARGV[0]})/util.sh"

function acquire(){
# $1: filelock
#
    local filelock=$1

    if [ -f "$filelock" ]
    then
        local pid="$(cat $filelock)"
        echoerr -e "\033[1;31mError: JuJu already running on pid: $pid\033[0m"
        echo -e "If you are sure a JuJu is not already"
        echo -e "running, you can remove $filelock"
        return 1
    fi
    mkdir -p $(dirname "$filelock")

    echo "$BASHPID" > "$filelock"
}

function release(){
# $1: filelock
#
    local filelock=$1

    rm -rf "$filelock" &> /dev/null
}
