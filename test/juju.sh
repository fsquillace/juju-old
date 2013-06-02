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



function test_install_package(){
    
    JUJU_PACKAGE_HOME=$(mktemp --tmpdir=/tmp -d juju_test.XXXXXXXXXX)
    source lib/juju/core.sh
    # Setup
    local pkg_list=('unionfs-fuse' 'htop' 'tcpdump' 'sysstat' 'iptraf')

    for pkg in ${pkg_list[@]}
    do
        local res=$(confirm_question "Do you want test $pkg? (Y/n)> ")
        if [ "$res" == "N" ] || [ "$res" == "n" ]; then
            continue
        fi
        
        install_package $pkg true || \
            echo -e "\033[1;31mError on installation test of the package $pkg.\033[0m"
    done

    # TearDown
    rm -rf $JUJU_PACKAGE_HOME
}


test_install_package
