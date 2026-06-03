#!/usr/bin/env bash

switch_env_new(){

    #new env during creation
    . "$CONFIG_FILE"



    local current_env="$(get_current_env)"
    local env="$LABEL"

    local local_file="$CACHE_DIR/$env"


    if [[ -e "$CACHE_DIR/podboi_env" ]]; then
        \printf "PODBOI_CURRENT_ENV='%s'\n" "$env" > "$CACHE_DIR/podboi_env" || {
            \printf "\n[ERROR] an error occured changing the environment!\n\n";
            return 17;
            }
    fi

    local check="$?"

    if [[ $check -ne 0 ]]; then

       \printf "PODBOI_CURRENT_ENV='%s'\n" "$current_env" > "$CACHE_DIR/podboi_env" || {
            \printf "\n[ERROR] an error occured changing the environment back!\n\n";
            return 17;
            }

        return "$check"

    fi

    return 0

}

switch_env(){


    #search if environment exists by searching the local_podboi folder's files - no actually search using podman ps

    #this is where a function to delete all podboi containers will be useful

     local env="$1"
     local cache_file="$CACHE_DIR/$podboi_env"


        if [[ -z "$env" ]]; then

            \printf "\n[ERROR] env cannot be empty!\n\n" "$env"
            return 17

        fi


        if [[ ! -e "$LOCAL_DIR/$env" ]]; then

            \printf "\n[ERROR] %s doesn't exist!\n\n" "$env"
            return 17

        fi


        if [[ ! -d "$CACHE_DIR" ]]; then

        \mkdir -p "$CACHE_DIR" || { 
            \printf "\n[ERROR] The %s folder could not be created - try creating yourself with correct permissions!\n\n" "$CACHE_DIR_LOCAL"; 
            return 16; 
            } 

        fi


        if [[ ! -f "$cache_file" ]]; then

            \touch "$cache_file" || { 
                \printf "\n[ERROR] An error occured creating %s\n\n" "$CACHE_FILE"; 
                return 16; 
                }

        fi


        \printf "PODBOI_CURRENT_ENV='%s'\n" "$env" > "$CACHE_DIR/podboi_env" || {
            \printf "\n[ERROR] an error occured changing the environment!\n\n";
            return 17;
            }

    return 0

}

switch_env_script_main(){



    case "$1" in


        --new)
        
            shift
            switch_env_new "$1" || return "$?"

        ;;

        --switch)

            shift
            switch_env "$1" || return "$?"

        ;;


    esac

    return 0


}

switch_env_script_main "$@" || return "$?"