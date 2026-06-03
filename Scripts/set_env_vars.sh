#!/usr/bin/env bash

if [ -n "$BASH_VERSION" ]; then
    SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
elif [ -n "$ZSH_VERSION" ]; then
    SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

#Add all to the variable file. 
#.cache file holds env - the label
#.local file path is defined by set_cache_local.sh $MODE 
#-this will store the variables

USER_DEFINED_MODE="local"



source_set_cache_local(){


    . "$SCRIPTS_DIR/set_cache_local.sh" "$USER_DEFINED_MODE" || { 
        \printf "\n[ERROR] An error occured sourcing %s/set_cache_local.sh\n\n" "$SCRIPTS_DIR"; 
        return 15; 
    }


}


set_cache_file(){

    #THIS WILL BE A DIFFERENT FUNCTION ELSEWHERE FOR THE SWITCH-ENV FUNCTION!

    CACHE_FILE="$CACHE_DIR/podboi_env"

    \touch "$CACHE_FILE" || { 
        \printf "\n[ERROR] An error occured creating %s\n\n" "$CACHE_FILE"; 
        return 16; 
    }

    \chmod 755 "$CACHE_FILE" || { 
        \printf "\n[ERROR] An error occured running 'chmod 755 %s'\n\n" "$CACHE_FILE"; 
        return 16; 
    }

    \printf "PODBOI_CURRENT_ENV=%s" "$USER_DEFINED_LABEL" > "$CACHE_FILE" || { 
        \printf "\n[ERROR] An error occured writing to %s" "$CACHE_FILE"; 
        return 16; 
    }
    
    return 0

}


set_local_file(){

    LOCAL_FILE="$LOCAL_DIR/$USER_DEFINED_LABEL"

     \touch "$LOCAL_FILE" || { 
        \printf "\n[ERROR] An error occured running 'touch %s'\n\n" "$LOCAL_FILE"; 
        return 16; 
    }

    \chmod 755 "$LOCAL_FILE" || { 
        \printf "\n[ERROR] An error occured running 'chmod 755 %s'\n\n" "$LOCAL_FILE"; 
        return 16; 
    }

    return 0

}


set_env_vars(){


        #-ROOTFUL
        \printf "USER_DEFINED_ROOTFUL=\"%s\"\n" "$USER_DEFINED_ROOTFUL" > "$LOCAL_FILE"

        #-POD
        \printf "USER_DEFINED_POD=\"%s\"\n" "$USER_DEFINED_POD" >> "$LOCAL_FILE"

        #-POD NAME
        if [[ "$USER_DEFINED_POD" == "true" ]]; then
            \printf "USER_DEFINED_POD_NAME=\"%s\"\n" "$USER_DEFINED_POD_NAME" >> "$LOCAL_FILE"
        fi

        #-LABEL
        \printf "USER_DEFINED_LABEL=\"%s\"\n" "$USER_DEFINED_LABEL" >> "$LOCAL_FILE"

        # [NOTE] The extra space is just to get nicer output without writing a forloop - these vars are unecessary, but nice for the User
        #-POD PORTS
        if (( ${#USER_DEFINED_POD_PORTS[@]} > 0 )); then
            \printf "USER_DEFINED_POD_PORTS=(" >> "$LOCAL_FILE"
            \printf " \"%q\" " "${USER_DEFINED_POD_PORTS[@]}" >> "$LOCAL_FILE"
            \printf ")\n" >> "$LOCAL_FILE"
        fi

        #-NO. OF CONTAINERS
        \printf "USER_DEFINED_NO_OF_CONTAINERS=%s\n" "$USER_DEFINED_NO_OF_CONTAINERS" >> "$LOCAL_FILE"
        
        #-IMAGES
        \printf "USER_DEFINED_IMAGES=(" >> "$LOCAL_FILE"
        \printf " \"%q\" " "${USER_DEFINED_IMAGES[@]}" >> "$LOCAL_FILE"
        \printf ")\n" >> "$LOCAL_FILE"
        
        #-VOLUMES
        if (( ${#USER_DEFINED_VOLUMES[@]} > 0 )); then
            \printf "USER_DEFINED_VOLUMES=(" >> "$LOCAL_FILE"
            \printf " \"%q\" " "${USER_DEFINED_VOLUMES[@]}" >> "$LOCAL_FILE"
            \printf ")\n" >> "$LOCAL_FILE"
        fi

        #-NETWORK
        if [[ "$USER_DEFINED_POD" != "true" ]]; then
            \printf "USER_DEFINED_NETWORK=\"%s\"\n" "$USER_DEFINED_NETWORK" >> "$LOCAL_FILE"
        fi

        #-Interactive Terminal
        \printf "USER_DEFINED_INTERACTIVE_TERMINAL=\"%s\"\n" "$USER_DEFINED_INTERACTIVE_TERMINAL" >> "$LOCAL_FILE"

        #-STARTUP SCRIPT
        if [[ ! -z "$USER_DEFINED_STARTUP_SCRIPT" ]]; then
            \printf "USER_DEFINED_STARTUP_SCRIPT=\"%s\"\n" "$USER_DEFINED_STARTUP_SCRIPT" >> "$LOCAL_FILE"
        fi

        return 0

}

set_env_vars_main(){

    source_set_cache_local || return "$?"

    set_cache_file || return "$?"
    set_local_file || return "$?"

    set_env_vars

}

set_env_vars_main || return "$?"