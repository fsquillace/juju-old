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

# References:
# https://wiki.archlinux.org/index.php/PKGBUILD
# https://wiki.archlinux.org/index.php/Creating_Packages

# Import util.sh first
FILE="$(readlink -f ${BASH_ARGV[0]})"
source "$(dirname ${BASH_ARGV[0]})/util.sh"

set -e
# TODO make a general control of the main commands (wget, tar, etc)
# TODO make a lock system

################################ REPOSITORY SCRIPTS #######################################
OFFICIAL_REPO="https://projects.archlinux.org"
OFFICIAL_PACKAGES_REPO="$OFFICIAL_REPO/svntogit/packages.git"
OFFICIAL_COMMUNITY_REPO="$OFFICIAL_REPO/community.git"

AUR_URL='http://aur.archlinux.org/'
AUR_SEARCH_URL="$AUR_URL/rpc.php?"

[ -z "$JUJU_PACKAGE_HOME" ]  && JUJU_PACKAGE_HOME="$HOME/.juju"
JUJU_PACKAGE_HOME=$(readlink -f $JUJU_PACKAGE_HOME)
if [ ! -d "$JUJU_PACKAGE_HOME" ]
then
    echoerr -e "\033[1;31mError: The path '$JUJU_PACKAGE_HOME' doesn't exist\033[0m"
    exit 128
fi


[ -z $JUJU_DEBUG ]  && JUJU_DEBUG=0


function search_package(){
    # Search a package into the repositoriesries AUR and Official
    # $1: package name
    # return: 0 if package found, 1 otherwise
    local DATA=$(wget -q -O - "${AUR_SEARCH_URL}type=search&arg=yaourt")
}

function info_package(){
    # Get information of a package
    # $1: package name
    # return: the infos
    echo
}

function check_integrity(){
    # TODO Check if the metadata are correctly matched with the root dir
    echo
}

function download_package(){
    # Download a package a place the PKGBUILD and other files to the maindir
    # Usage: update_package <pkgname> <maindir> [<jujudir>]
    # $1: pkgname - Package name
    # $2: maindir - Directory where the package will be downloaded
    # return: 0 if successfully downloaded and 1 otherwise

    # Ensure to have the absolute paths
    local maindir=$(readlink -f $2)

    # Check to the official repositories first
    local repos=("packages" "community")
    local in_official=false
    for repo in ${repos[@]}
    do
        if download_package_from_official $1 $maindir $repo
        then
            in_official=true
            break
        fi
    done

    # Check in AUR at the end
    if ! $in_official
    then
        download_package_from_aur $1 $maindir || return 1
    fi

    return 0
}

function download_package_from_aur(){
    # Download a package from AUR repo a place the PKGBUILD and other files to the maindir
    # Usage: download_package_from_aur <pkgname> <maindir>
    # $1: pkgname - Package name
    # $2: maindir - Directory whare the package will be downloaded
    # return 0 if the package was successfully downloaded and 1 otherwise

    # Ensure to have the absolute paths
    local maindir=$(readlink -f $2)

    local json_info=$(wget -q -O - "$AUR_URL/rpc.php?type=info&arg=$1")
    echo "$json_info" | grep "URLPath" &> /dev/null || return 1
    local pathURL=$(echo $json_info | awk -F [,:\"] '{c=1; while(var!="URLPath"){var=$c;c++}; print $(c+2)}')

    wget -P $maindir $(echo ${AUR_URL}${pathURL} | sed 's/\\//g')
    # Extract the PKGBUILD&co in the main directory
    tar -C $maindir -xzvf ${pkgname}.tar.gz
    mv $maindir/$pkgname/* . && rm -fr $maindir/$pkgname

}

function download_package_from_official(){
    # Download a package from Official a place the PKGBUILD and other files to the maindir
    # Usage: download_package_from_official <pkgname> <maindir>
    # $1: pkgname - Package name
    # $2: maindir - Directory where the package will be downloaded
    # $3: reponame - Repository name (Default: packages)
    # return 0 if the package was successfully downloaded and 1 otherwise

    local repo="packages"
    [ ! -z $3 ] && repo="$3"

    # Ensure to have the absolute paths
    local maindir=$(readlink -f $2)

    local xml_info=$(wget -q -O - "$OFFICIAL_REPO/svntogit/$repo.git/plain/trunk/?h=packages/$1")
    if [ "$xml_info" == "" ]; then
        # Package not in this repository
        return 1
    fi

    # Get the url list of file to download
    local list=$(echo "$xml_info" | grep -E -o "href\s*=\s*.*>" | cut -d \' -f2 | sed -e 's,^,'"$OFFICIAL_REPO"',g' | xargs)

    for w in $list; do
        # Get the filename from the url
        local name=$(echo "$w" | sed -e 's,^'"$OFFICIAL_REPO"'/svntogit/'"$repo"'.git/plain/trunk/,,g' -e 's\?.*\\g' -e 's,'"$OFFICIAL_REPO"'/svntogit/'"$repo"'.git/plain/,,g' )
        if [ "$name" != "" ]; then
            builtin cd $maindir
            wget -P "$maindir" -O $name $w
            builtin cd -
        fi
    done

    return 0
}

function download_precompiled_package(){
    # Download the pre-compiled package from Official repository
    # Usage: download_precompiled_package <pkgname> <destdir>
    # $1: pkgname - Package name
    # $2: pkgver - Package version
    # $3: arch - Architecture
    # $4: maindir - Directory where the package will be downloaded
    # $5: reponame - Repository name (by default scan through all repos)
    # return 0 if succesfully downloaded 1 otherwise

    local pkgname=$1
    local pkgver=$2
    local arch=$3
    # Ensure to have the absolute paths
    local maindir=$(readlink -f $4)

    local repos=("core" "extra" "community" "multilib" "testing" "community-testing" "multilib-testing")
    [ ! -z $5 ] && repos=("$5")
    local ret="1"
    for (( i=0; i<${#repos[@]}; i++ ))
    do
        wget -P "$maindir" -O ${pkgname}-${pkgver}-${arch}.pkg.tar.xz https://www.archlinux.org/packages/${repos[i]}/${arch}/${pkgname}/download/
        ret=$?
        [ "$ret" == "0" ] && break
    done

    return $ret
}

function compile_package(){
    # Compile the package using the PKGBUILD variables
    # Usage: compile_package <> <>
    # return 0 if package successfully compiled, 1 otherwise

    for (( i=0; i<${#source[@]}; i++ ))
    do
        local s=${source[i]}

        if [ -f "$s" ]; then
            mv -f $s $srcdir/
            local sourcename=$s
        else
            echo -e "\033[1;37mDownloading $s ...\033[0m"
            wget -P $srcdir $s
            local sourcename=$(basename $s)
        fi

        # Check sum for each file downloaded
        echo -e "\033[1;37mChecking sum ...\033[0m"
        [ ! -z $md5sums ] && (check_sum "$srcdir/$sourcename" ${md5sums[i]} "md5sum" || return 1)
        [ ! -z $sha1sums ] && (check_sum "$srcdir/$sourcename" ${sha1sums[i]} "sha1sum" || return 1)
        [ ! -z $sha256sums ] && (check_sum "$srcdir/$sourcename" ${sha256sums[i]} "sha256sum" || return 1)
        [ ! -z $sha384sums ] && (check_sum "$srcdir/$sourcename" ${sha384sums[i]} "sha384sum" || return 1)
        [ ! -z $sha512sums ] && (check_sum "$srcdir/$sourcename" ${sha512sums[i]} "sha512sum" || return 1)

        echo -e "\033[1;37mExtracting ...\033[0m"
        # TODO try to substitute atool
        # extract $srcdir/$sourcename $srcdir
        atool -f --extract-to=$srcdir $srcdir/$sourcename
    done

    echo -e "\033[1;37mBuilding...\033[0m"
    builtin cd $srcdir
    [ "$(type -t pkgver &> /dev/null)" == "function" ] && pkgver
    builtin cd $srcdir
    type -t prepare &> /dev/null && prepare
    builtin cd $srcdir
    type -t build &> /dev/null && build # && echoerr "Error: build function not worked."; return 1
    builtin cd $srcdir
    type -t check &> /dev/null && check

    echo -e "\033[1;37mPackaging...\033[0m"
    builtin cd $srcdir
    type -t package &> /dev/null && package # && echoerr "Error: package function not worked."; return 1
    builtin cd $srcdir
    type -t package_$pkgname &> /dev/null && package_$pkgname

    return 0
}

function read_pkgbuild() {
    # Read PKGBUILD
    # PKGBUILD must be in current directory
    #
    # Usage:	read_pkgbuild ($update)
    #	$update: 1: call devel_check & devel_update from makepkg
    # Set PKGBUILD_VARS, exec "eval $PKGBUILD_VARS" to have PKGBUILD content.


    # Before starting ensure that the PKGBUILD variables are reset
    vars=(pkgbase pkgname pkgver pkgrel epoch pkgdesc arch provides url \
        groups license source install md5sums sha1sums depends makedepends checkdepends \
        optdepends conflicts sha256sums sha384sums sha512sums \
        replaces backup options install changelog noextract \
        package check build \
        _svntrunk _svnmod _cvsroot_cvsmod _hgroot _hgrepo \
        _darcsmod _darcstrunk _bzrtrunk _bzrmod _gitroot _gitname \
    )
    unset ${vars[*]}

    source $maindir/PKGBUILD

}

function check_version_condition(){
#
# $1: pkgver (mandatory)a str - i.e. "3.4.5"
# $2: vercondition (mandatory): str -
#     The condition are ">=","<=",">","<","=".
#     i.e. of vercondition ">=3.4.6"
# Return 0 if the pkgver assert the condition, 1 otherwise

    local ver=$1
    local cond=$(echo "$2" | grep -o -e ">=" -e "<=" -e ">" -e "<" -e "=")
    local vercond="$(echo "$2" | awk -F "$cond" '{print $2}')"
    if [[ "$cond"  == ">" ]]; then
        [[ "$ver" > "$vercond" ]]
    elif [[ "$cond"  == "<" ]]; then
        [[ "$ver" < "$vercond" ]]
    elif [[ "$cond"  == "=" ]]; then
        [[ "$ver" == "$vercond" ]]
    elif [[ "$cond"  == ">=" ]]; then
        [[ "$ver" > "$vercond" ]] || [[ "$ver" == "$vercond" ]]
    elif [[ "$cond"  == "<=" ]]; then
        [[ "$ver" < "$vercond" ]] || [[ "$ver" == "$vercond" ]]
    else
        return 1
    fi
}

function install_package(){
    # Download and build the package in a temp directory and move the package
    # built in $JUJU_PACKAGE_HOME
    #
    # Usage: install_package <pkgname> [<jujudir> <from_source>]
    # $1: pkgname (mandatory): str -name of the package
    # $2: from_source (optional): bool - true for installing package from source,
    #     try to take pre-compiled otherwise
    #     (default: false it detects that the arch matches)
    # $3: version condition (optional): str - syntax '<condition><version>',
    #     which condition={'>=','<=','>','<','='}
    #     for example '>=5.4'

    # TODO add a verbose option and ignore-errors option

    local from_source=false
    [ -z "$2" ] || from_source=$2

    local vercondition=""
    [ -z "$3" ] || vercondition=$3

    # Create the dirs
    mkdir -p $JUJU_PACKAGE_HOME/root
    mkdir -p $JUJU_PACKAGE_HOME/metadata/packages
    mkdir -p $JUJU_PACKAGE_HOME/metadata/repos

    # Store the original working directory
    local origin_wd=$(pwd)

    # DEFINE MAIN VARIABLES GLOBALLY
    pkgname=$1
    maindir=$(mktemp --tmpdir=/tmp -d juju.XXXXXXXXXX) #/juju_pkg_${pkgname}_$(date +"%Y%m%d-%H%M%S")
    # Old PKGBUILD version use startdir instead of maindir
    startdir=$maindir
    srcdir=$maindir/src
    pkgdir=$maindir/pkg

    [ -d $JUJU_PACKAGE_HOME/metadata/packages/${pkgname} ] && echo -e "\033[1;37mUpdating package ${pkgname} ...\033[0m"

    mkdir -p $srcdir
    mkdir -p $pkgdir

    # Trap for removing the directory when the script finished
    [ "$JUJU_DEBUG" == "1" ] && trap "/bin/rm -fr $maindir" QUIT EXIT ABRT KILL TERM
    trap "rollback_and_die $pkgname \"Error occurred when installing $pkgname\"" QUIT EXIT ABRT KILL TERM

    builtin cd $maindir

    download_package $pkgname $maindir || rollback_and_die $pkgname "Error: The package $pkgname doesn't exist neither in Official nor AUR repos"

    # Before sourcing PKGBUILD ask if user want to change it
    local res=$(confirm_question "Do you want to change the PKGBUILD? (y/N)> ")
    if [ "$res" == "Y" ] || [ "$res" == "y" ]; then
        cmd_edit=$EDITOR
        [ -z $EDITOR ] && cmd_edit=nano
        $cmd_edit $maindir/PKGBUILD
    fi

    read_pkgbuild

    if [ -n "$vercondition" ]; then
        echo -e "\033[1;37mChecking versioning $pkgver $vercondition.\033[0m"
        check_version_condition "$pkgver" "$vercondition" \
        || rollback_and_die $pkgname "Error: The package $pkgname doesn't match the version condition $vercondition"
    fi

    # TODO handle package splitting (like vim and python2-pylint)
    if ( [ "${#pkgname[@]}" != "1"  ] ) && ( $from_source )
    then
        echoerr -e "\033[1;31mError: The package splitting is not implemented yet from JuJu. Try to install using pre-compiled.\033[0m"
        return 1
    fi

    # Check for the architecture and ask to continue
    local myarch=$(uname -m)
    local match_arch=false
    for a in ${arch[@]}; do
        if [ $a == "any" ]; then
            myarch="$a"
        fi
        if [ $a == $myarch ]; then
            match_arch=true
            break
        fi
    done

    if ! $match_arch
    then
        local res=$(confirm_question "The architecture $myarch is not suitable for $pkgname package. Do you want to continue anyway? (Y/n)> ")
        if [ "$res" == "N" ] || [ "$res" == "n" ]; then
            return 1
        fi
    fi


    # manage the dependencies of the package
    echo -e "\033[1;37mCheck for dependencies...\033[0m"
    echo -e "\033[1;37mList of dependencies: ${depends[@]} ${makedepends[@]}\033[0m"
    # Consider the dependencies installed by the user through installed_deps
    local installed_deps=""
    for dep in "${depends[@]}" "${makedepends[@]}"
    do
        # Handle the version condition such as 'linux-header>=3.7'
        local condition=$(echo "$dep" | grep -o -e ">=" -e "<=" -e ">" -e "<" -e "=")
        if [ -n "$condition" ]; then
            local depvercondition="${condition}$(echo "$dep" | awk -F "$condition" '{print $2}')"
            dep=$(echo "$dep" | awk -F "$condition" '{print $1}')
        fi

        local res=$(confirm_question "Do you want to install $dep package? (Y/n)> ")
        if [ "$res" == "Y" ] || [ "$res" == "y" ] || [ "$res" == "" ]; then
            installed_deps+=("'"$dep"'")
            /bin/bash -c "export JUJU_PACKAGE_HOME=$JUJU_PACKAGE_HOME; source $FILE; install_package \"$dep\" $from_source \"$depvercondition\"" || \
                rollback_and_die $pkgname "Error: dependency package $dep not installed."
        fi

        # Be sure to unset the variable
        unset condition
        unset depvercondition
    done


    if ( [ -z $from_source ] && $match_arch ) || ( ! $from_source)
    then
        echo -e "\033[1;37mGetting pre-compiled package...\033[0m"
        if download_precompiled_package $pkgname $pkgver $myarch $maindir
        then
            builtin cd $pkgdir
            # to extract we can use tar Jxvf but probably using xz command is more portable
            if xz -d ../${pkgname}-${pkgver}-${myarch}.pkg.tar.xz
            then
                tar xvf ../${pkgname}-${pkgver}-${myarch}.pkg.tar
            else
                echoerr -e "\033[1;31mError: xz command doesn't exist (Try to install it first)\033[0m"
                echo -e "\033[1;37mCompiling from source files...\033[0m"
                compile_package || rollback_and_die $pkgname "Error when compiling the package $pkgname"
            fi
            builtin cd $OLDPWD
        else
            echoerr -e "\033[1;33mWarn: pre-compiled package not available, compiling it...\033[0m"
            compile_package || rollback_and_die $pkgname "Error when compiling the package $pkgname"
        fi
    else
        echo -e "\033[1;37mCompiling from source files...\033[0m"
        compile_package || rollback_and_die $pkgname "Error when compiling the package $pkgname"
    fi

    # Check if the package is already installed and remove the previous files
    if [ -d $JUJU_PACKAGE_HOME/metadata/packages/${pkgname} ]; then
        remove_package "${pkgname}" false &> /dev/null || \
            echoerr -e "\033[1;33mWarn: Got an error when removing ${pkgname} old version. Continuing updating ${pkgname} anyway ...\033[0m"
    fi

    # Check the .install file
    if [ -n "$install" ] &&  [ -f "$maindir/${install}" ]; then
        source $maindir/${install}
        builtin cd $JUJU_PACKAGE_HOME/root
        type -t pre_install &> /dev/null && pre_install $pkgver
    fi


    echo -e "\033[1;37mInstalling into the system...\033[0m"
    mkdir -p $JUJU_PACKAGE_HOME/metadata/packages/$pkgname
    # Ensure to have the matadata folder empty
    rm -r -f $JUJU_PACKAGE_HOME/metadata/packages/$pkgname/*
    # Copy the PKGBUILD and .install as metadata of the package
    cp -f -a $maindir/PKGBUILD $JUJU_PACKAGE_HOME/metadata/packages/$pkgname/
    [ -f $maindir/*.install ] && cp -f -a $maindir/*.install $JUJU_PACKAGE_HOME/metadata/packages/$pkgname/

    builtin cd $pkgdir
    if [ -f .PKGINFO ]; then
        grep -e builddate -e packager .PKGINFO | awk -F " = " '{print $1"=\""$2"\""}' >> "$JUJU_PACKAGE_HOME/metadata/packages/${pkgname}/PKGINFO"
        rm -f .PKGINFO
    fi
    [ -f .MTREE ] && rm -f .MTREE
    local packpaths="$(du -ab)"
    local size=$(echo "$packpaths" | tail -n 1 | awk '{print $1}')
    local packpaths=$(echo "$packpaths" | cut -f2- | awk -v q="$JUJU_PACKAGE_HOME/root" '{sub("^.",q);print}')
    echo "instsize=\"$size\"" >> "$JUJU_PACKAGE_HOME/metadata/packages/${pkgname}/PKGINFO"
    echo "instdate=\"$(date +%s)\"" >> "$JUJU_PACKAGE_HOME/metadata/packages/${pkgname}/PKGINFO"
    echo "instdeps=(${installed_deps[@]})" >> "$JUJU_PACKAGE_HOME/metadata/packages/${pkgname}/PKGINFO"
    echo "$packpaths" > "$JUJU_PACKAGE_HOME/metadata/packages/${pkgname}/FILES"

    # TODO Check conflicts between the package and the root directory
    #du -ab "$JUJU_PACKAGE_HOME/root/" "$packpaths" | grep -x -F -f $JUJU_PACKAGE_HOME/metadata/packages/${pkgname}/${pkgname}.paths

    # The following cmds are dangerous! Could dirty the installation directory
    cp -f -v -a --target-directory $JUJU_PACKAGE_HOME/root *

    echo -e "\033[1;37m$pkgname installed successfully\033[0m"

    if [ -n "$install" ] && [ -f "$maindir/${install}" ]; then
        builtin cd $JUJU_PACKAGE_HOME/root
        type -t post_install &> /dev/null && post_install $pkgver
    fi

    # Resets all PKGBUILD variables and returns to the original wd
    unset ${vars[*]}
    cd $origin_wd

    # Remove all previous traps
    trap - QUIT EXIT ABRT KILL TERM
    return 0
}

function rollback_and_die(){
# Apply the rollback procedure and give the error message
# $1: package name
# $2: Message to print

    echoerr -e "\033[1;31m$2\033[0m"
    echo -e "\033[1;37mExecuting rollback procedure...\033[0m"
    remove_package $1 false  2> /dev/null && \
        echo -e "\033[1;37mRollback procedure completed successfully\033[0m" || \
        echoerr -e "\033[1;31mRollback procedure failed\033[0m"

    trap - QUIT EXIT ABRT KILL TERM
    exit 1
}

function remove_package(){
    # Remove the package from $JUJU_PACKAGE_HOME
    #
    # Usage: remove_package <pkgname> [<jujudir>]
    # $1: name of the package
    # $2: interactive (default true)

    local pkgname=$1
    if [ -z "$pkgname" ]
    then
        echoerr -e "\033[1;31mError: Package name not specified\033[0m"
        return 128
    fi

    local interactive=true
    [ ! -z $2 ] && interactive=$2

    if [ ! -d "$JUJU_PACKAGE_HOME/metadata/packages/${pkgname}" ]
    then
        echoerr -e "\033[1;31mError: The package $pkgname is not installed\033[0m"
        return 1
    fi

    # Delete the dependencies first
    source "$JUJU_PACKAGE_HOME/metadata/packages/${pkgname}/PKGINFO"
    echo -e "\033[1;37mCheck for dependencies...\033[0m"
    if [ ! -z $instdeps ]; then
        echo -e "\033[1;37mList of dependencies: ${instdeps[@]}\033[0m"
        for dep in ${instdeps[@]}
        do
            local res="y"
            $interactive && res=$(confirm_question "Do you want remove $dep package? (y/N)> ")
            if [ "$res" == "y" ] || [ "$res" == "Y" ]; then
                /bin/bash -c "source $FILE; remove_package $dep $JUJU_PACKAGE_HOME $interactive"
            fi
        done
    fi

    cat "$JUJU_PACKAGE_HOME/metadata/packages/${pkgname}/FILES"
    local res="y"
    $interactive && res=$(confirm_question "Do you want remove $pkgname package? (y/N)> ")
    if [ "$res" == "n" ] || [ "$res" == "N" ] || [ "$res" == "" ]; then
        return 1
    fi

    for element in  $(cat "$JUJU_PACKAGE_HOME/metadata/packages/${pkgname}/FILES" | xargs)
    do
        if [ -f $element ] || [ -L $element ]
        then
            rm -f $element
        elif [ -d $element ] && [ ! "$(ls -A "$element")" ]
        then
            rm -r -f $element
        fi
    done

    if ! rm -r -f "$JUJU_PACKAGE_HOME/metadata/packages/${pkgname}"
    then
        echoerr -e "\033[1;31mError: Metadata for $pkgname were not removed\033[0m"
        return 1
    fi

    return 0
}

