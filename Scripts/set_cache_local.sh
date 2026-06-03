#!/usr/bin/env bash

if [ -n "$BASH_VERSION" ]; then
    SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
elif [ -n "$ZSH_VERSION" ]; then
    SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

#do a check to see if user can, also add check root!
#and make the same name for directories
#think about the ~/.local/state/ folder, gh and nvim uses it....


set_to_local(){

    CACHE_DIR="$SCRIPTS_DIR/../.cache_podboi"
    LOCAL_DIR="$SCRIPTS_DIR/../.local_podboi"

    \mkdir -p "$CACHE_DIR" || { 
        \printf "\n[ERROR] The %s folder could not be created - try creating yourself with correct permissions!\n\n" "$CACHE_DIR_LOCAL"; 
        return 16; 
        } 

    \mkdir -p "$LOCAL_DIR" || { 
        \printf "\n[ERROR] The %s folder could not be created - try creating yourself with correct permissions!\n\n" "$LOCAL_DIR_LOCAL"; 
        return 16; 
        } 

    return 0

}

set_to_system_wide(){

    CACHE_DIR_SYSTEM_WIDE="/var/lib/PodBOI/.cache_podboi"
    LOCAL_DIR_SYSTEM_WIDE="/var/lib/PodBOI/.local_podboi"

    \mkdir -p "$CACHE_DIR" || { 
        \printf "\n[ERROR] The %s folder could not be created - try creating yourself with correct permissions!\n\n" "$CACHE_DIR_SYSTEM_WIDE"; 
        return 16; 
        } 

    \mkdir -p "$LOCAL_DIR" || { 
        \printf "\n[ERROR] The %s folder could not be created - try creating yourself with correct permissions!\n\n" "$LOCAL_DIR_SYSTEM_WIDE"; 
        return 16; 
        } 

    return 0

}

set_to_userspace(){


    #Maybe check if exists first
    #Some check_root, and see if the current User is able to read/write from the file
    CACHE_DIR_USERSPACE="~/.cache/PodBOI"
    LOCAL_DIR_USERSPACE="~/.local/PodBOI"
    

    \mkdir -p "$CACHE_DIR" || { 
        \printf "\n[ERROR] The %s folder could not be created - try creating yourself with correct permissions!\n\n" "$CACHE_DIR_USERSPACE"; 
        return 16; 
    } 

    \mkdir -p "$LOCAL_DIR" || { 
        \printf "\n[ERROR] The %s folder could not be created - try creating yourself with correct permissions!\n\n" "$LOCAL_DIR_USERSPACE"; 
        return 16; 
    } 

    return 0

}


set_cache_local_main(){

    if (($# > 1)); then

        \printf "\n[ERROR] Too many args have been entered!\n\n"
        return 14

    fi


    case "$1" in

        local)

            set_to_local

        ;;

        system-wide)

            set_to_system_wide

        ;;

        user)

            set_to_userspace

        ;;

        *)

            \printf "\n[ERROR] Invalid entry\n\n"
            return 14

        ;;

    esac


    return 0

}

set_cache_local_main "$1" || return "$?"