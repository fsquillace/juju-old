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

function confirm_question(){
    # $1: prompt;

    local res="none"
    while [ "$res" != "Y" ] && [ "$res" != "n" ] && [ "$res" != "N"  ] && [ "$res" != "y"  ] && [ "$res" != "" ];
    do
        read -p "$1" res
    done

    echo "$res"
}

echoerr() { echo "$@" 1>&2; }

function findformat() {
# Get the format of the given file
# Return an empty string if the file is not valid
# $1: filename
# return: the extension file like '.<extension_name>'
# If the extension is not specified directly into the filename, the
# function return a 'n' prefix like 'n.<extension_name>'
#
    local filename=$(readlink -f $1)
    local format=""
    if [ ! -f $filename ] ; then
        echo "'$1' is not a valid file!"
        return 1
    fi
    case $filename in
	*.tar.bz2)  format='.tar.bz2' ;;
	*.tar.gz)   format='.tar.gz' ;;
	*.tar.xz)   format='.tar.xz' ;;
	*.xz)       format='.xz' ;;
	*.bz2)      format='.bz2' ;;
	*.rar)      format='.rar' ;;
	*.gz)       format='.gz' ;;
        *.tar)      format='.tar' ;;
        *.tbz2)     format='.tbz2' ;;
        *.tgz)      format='.tgz' ;;
        *.zip)      format='.zip' ;;
        *.Z)        format='.Z' ;;
        *.7z)       format='.7z' ;;
        *)          format="" ;;
    esac

    if [ "$format" == "" ]
    then
        local file_info=$(file $filename | tr '[:upper:]' '[:lower:]')
        case $file_info in
	    *\ gzip\ *)       format='n.gz' ;;
	    *\ xz\ *)         format='n.xz' ;;
            *\ bzip2\ *)      format='n.bz2' ;;
	    *\ rar\ *)        format='n.rar' ;;
            *\ tar\ *)        format='n.tar' ;;
	    *\ zip\ *)        format='n.zip' ;;
 	    #*\ Z\ *)         format='n.Z' ;;
	    *\ 7z\ *)         format='n.7z' ;;
	    *)                format="" ;;
        esac
    fi

    echo $format
    return 0
}

function extract(){
# Extract the content of the compressed file
# in the specified folder
#
# $1: filename (absolute path)
# $2: destination folder (default: directory of the compressed file)
#
    local filename=$(readlink -f $1)
    if [ ! -f $filename ]; then
        echo -e "\033[1;31mThe compressed file doesn't exist\033[0m"
        return 1
    fi

    local destdir=$(dirname $filename)
    [ ! -z $2 ] && destdir=$(readlink -f $2)
    if [ ! -d $destdir ]; then
        echo -e "\033[1;31mThe destination folder doesn't exist\033[0m"
        return 1
    fi

    local format=$(findformat $filename)
    [ "$format" == "" ]  && return
    local ext=".$(echo $format | cut -d '.' -f2- )"
    local nope=$(echo $format | cut -d '.' -f1 )
    echo $ext $nope

    local original_dir=$PWD
    builtin cd $destdir

    local old_filename=""
    # detect if the extension exists
    if [ "$nope" == "n" ]; then
        old_filename=$filename
        mv $filename ${filename}$ext
        filename=${filename}$ext
    fi

    case $ext in
        '.tar.bz2')     tar xvjf $filename ;;
        '.tar.gz')      tar xvzf $filename ;;
        '.tar.xz')      tar Jxvf $filename ;;
        '.xz')          xz -d $filename ;; #&& new_file=$(basename "$filename" .xz) ;;
        '.bz2')         bunzip2 $filename ;;
        '.rar')         unrar x $filename ;;
        '.gz')          gunzip $filename ;;
        '.tar')         tar xvf $filename ;;
        '.tbz2')        tar xvjf $filename ;;
        '.tgz')         tar xvzf $filename ;;
        '.zip')         unzip $filename ;;
        '.Z')           uncompress $filename ;;
        '.7z')          7z x $filename ;;
    esac

    if [ "$?" != "0" ]; then
        echo -e "\033[1;31mError extracting the content in $filename \033[0m"
        builtin cd $original_dir
        return 1
    fi

    # Handling recursion
    if [ -f "$old_filename" ]; then
        if ! extract "$old_filename" "$destdir"
        then
            builtin cd $original_dir
            return 1
        fi
    fi

    builtin cd $original_dir
    return 0
}

function check_sum(){
# Check sum by the command given a parameter
#
# $1: filename
# $2: sum to check
# $3: sum_command (default md5sum)
#
    local filename=$1
    local checksum=$2
    local sum_command="md5sum"
    [ ! -z $3 ] && sum_command="$3"
    [ "$checksum" == "SKIP" ] && return 0
    local sum=$($sum_command $filename | awk '{print $1}')
    if [ $sum != "$checksum" ]; then
        echo -e "\033[1;31mError: Not a correct checksum for $(basename $filename)\033[0m"
        return 1
    fi
    return 0
}
