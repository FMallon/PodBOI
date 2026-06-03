#!/usr/bin/env bash



#########################################################################################################################
#                                                                                                                       # 
#                                   PodBOI - The Podman Bash Orchestration Infratool                                    #
#
#   [DESCRIPTION] A light-weight & minimal Container Orchestration tool written purely in Bash 
#                                                                                              
#
#   [Dependencies]
#       Bash v4+
#       Podman
#       wc
#   
#   [NOTE] 
#        - Minor dependencies incl. lsof & less - but these aren't absolutely necessary   
#
#                                                                                                                       #
#                                                                                                    [AUTHOR] F. Mallon #
#                                                                                                 COPYRIGHT © F. Mallon #
#########################################################################################################################
#
# Return 1  - Error: Config File does not exist!
# Return 2  - Error: Max User Input on Attempts Reached         
# Return 3  - Error: Config Validation
# Return 4  - Error: Validation Container/Pod Pruning
# Return 5  - Error: Privilege escalation 
# Return 6  - Error: Displaying Containers
# Return 7  - Error: Stopping Containers
# Return 8  - Error: Killing Containers
# Return 9  - Error: Removing Containers
# Return 10 - Error: Container Instance already exists!
# Return 11 - Error: Copying into a Container
# Return 12 - Error: Starting a Container
# Return 13 - Error: Executing a Command into a Container
# Return 14 - Error: Invalid Args || Invalid Args inside the "--env" function 
# Return 15 - Error: Sourcing a file
# Return 16 - Error: Executing a Command in the CLI
# Return 17 - Error: Switching Environment
# Return 18 - Error: Pod doesn't exist                                          
# Return 19 - Error: Invalid Return Status in 'pod_exists' function
# Return 20 - Error: Creating Pod
# Return 21 - Error: Stopping/Killing the Pod
# Return 22 - Error: Starting the Pod
# Return 23 - Error: Removing the Pod
# Return 24 - Error: Getting the Status of the Pod
# Return 25 - Error: Creating a container
# Return 26 - Error: Container isn't running - the command cannot run unless the specified container is running
# Return 27 - Error: Container name exists elsewhere on the system
# Return 28 - Error: Invalid Root Privileges
# Return 29 - Error: If you get to this point: you're honestly thick as pig shit
# Return 30 - Error: Unsupported environment
# Return 31 - Error: There was an issue during the User Input Pod Validation Check - duplicate ports detected    
# Return 32 - Error: Invalid variable entry where the assignment an unexpected result - e.g. neither true nor false in a boolean assignment                                                   
# Return 33 - Error: Attaching to a Container
# Return 34 - Blocked: Attaching to a Container while $INTERACTIVE_TERMINAL=false                                                                                                                 #
#####################################################################################################################


##take args, set up a container, then run a startup script to carry out what's needed - no need for Dockerfiles and compose etc!


if [ -n "$BASH_VERSION" ]; then

    SOURCE="${BASH_SOURCE[0]}"

    INDEX_SPECIFIER=0
	READ_COMMAND=(read -r -p)
    READ_COMMAND_ARRAY_FLAG=(-a)

elif [ -n "$ZSH_VERSION" ]; then

    SOURCE="${(%):-%x}"

    INDEX_SPECIFIER=1
    USER_DEFINED_NO_OF_CONTAINERS=$((USER_DEFINED_NO_OF_CONTAINERS+1))
    READ_COMMAND=(read -r)
    READ_COMMAND_ARRAY_FLAG=(-A)

else

    \printf "\nThis is not a supported environment\n\n"
    return 30

fi

while [ -L "$SOURCE" ]; do

    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"

done

MAIN_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"

CONTAINER_SCRIPTS_DIR="$MAIN_DIR/../Container_Scripts"
CONFIG_DIR="$CONTAINER_SCRIPTS_DIR/Configs"
SCRIPTS_DIR="$MAIN_DIR/../Scripts"
LOG_DIR="$MAIN_DIR/../Logs"
#DOCUMENTATION_DIR="$MAIN_DIR/../Documentation"
CACHE_DIR="$MAIN_DIR/../.cache_podboi"
LOCAL_DIR="$MAIN_DIR/../.local_podboi"

###############################################
##Global Directories & Files##

PODMAN_DIR="$MAIN_DIR/Podman"

###############################################




check_root(){


    local root=""

    #check for current privilege status
    if [[ "$EUID" -eq 0 ]]; then 

        ROOT=()
        return 0

    fi

    #test for sudo or doas
    if command -v sudo >/dev/null 2>&1; then
        
        root=("sudo")
        ROOT=("${root[@]}")

    elif command -v doas >/dev/null 2>&1; then

        root=("doas")
        ROOT=("${root[@]}")

    else

        \printf "\n\n[ERROR] You need root privilege to run this - Sudo nor Doas appear to be installed!\n\n"
        return 28

    fi 
    
    
    return 0


}


# Moved to this function; therefore sudo/doas doesn't have to be stored in ./local/env_name which could be a cause of concern; 
# especially if you switch from a sudo machine to a doas etc.  It should work, though not stress-tested
escalate_root_privilege(){


    if [[ "$USER_DEFINED_ROOTFUL" == "true" ]]; then

        check_root || return "$?"
        return 0

    fi


}



source_global_commands(){

    . "$SCRIPTS_DIR/commands.sh" || { 
        \printf "\n[ERROR] There is a problem sourcing the Global Commands script (%s/commands.sh)\n\n" "$SCRIPTS_DIR"; 
        return 15; 
        }

}



print_line_separator(){


	\printf "___________________________________________________________________________________"


}


clear_space(){

    \printf "\n\n\n"

}


config_and_user_input_validation(){	


	#needs to be sourced to take-in the DEFAULTS specified above! These will be configurable, so best to leave them here.
    #-this will run the Config Validation, or User Input scripts!
    . "$SCRIPTS_DIR/user_input_validation.sh"


}

switch_environment(){


    local switch_env_script="$SCRIPTS_DIR/switch_env.sh"

    . "$switch_env_script" "$@"

}


manage_volume_mounting(){

    local index_specifier=$INDEX_SPECIFIER

    if [[ ${#USER_DEFINED_VOLUMES[@]} -lt $index_specifier ]]; then

        return 0
    
    fi

    VOLUME_ARGS=()

    for volume in "${USER_DEFINED_VOLUMES[@]}"; do

        if [[ ! -z "$volume" ]]; then

            VOLUME_ARGS+=("-v" "$volume")
        
        fi

    done

    return 0


}


print_env_vars(){

    
    
    clear_space
    print_line_separator
    clear_space

    source_env_vars

    \printf "  [ENVIRONMENT] " 
    get_current_env || return "$?"

    clear_space

    #-ROOTFUL
        \printf "    USER_DEFINED_ROOTFUL=\"%s\"\n" "$USER_DEFINED_ROOTFUL"

        #-POD
        \printf "    USER_DEFINED_POD=\"%s\"\n" "$USER_DEFINED_POD"

        #-POD NAME
        if [[ "$USER_DEFINED_POD" == "true" ]]; then
            \printf "    USER_DEFINED_POD_NAME=\"%s\"\n" "$USER_DEFINED_POD_NAME"
        fi

        #-LABEL
        \printf "    USER_DEFINED_LABEL=\"%s\"\n" "$USER_DEFINED_LABEL"

        # [NOTE] The extra space is just to get nicer output without writing a forloop - these vars are unecessary, but nice for the User
        #-POD PORTS
        if (( ${#USER_DEFINED_POD_PORTS[@]} > 0 )); then
            \printf "    USER_DEFINED_POD_PORTS=("
            \printf " \"%q\" " "${USER_DEFINED_POD_PORTS[@]}"
            \printf ")\n"
        fi

        #-NO. OF CONTAINERS
        \printf "    USER_DEFINED_NO_OF_CONTAINERS=%s\n" "$USER_DEFINED_NO_OF_CONTAINERS"
        
        #-IMAGES
        \printf "    USER_DEFINED_IMAGES=("
        \printf " \"%q\" " "${USER_DEFINED_IMAGES[@]}"
        \printf ")\n"

        #-VOLUMES
if (( ${#USER_DEFINED_VOLUMES[@]} > 0 )); then
            \printf "    USER_DEFINED_VOLUMES=("
            \printf " \"%q\" " "${USER_DEFINED_VOLUMES[@]}"
            \printf ")\n"
        fi

        #-NETWORK
        if [[ "$USER_DEFINED_POD" != "true" ]]; then
            \printf "    USER_DEFINED_NETWORK=\"%s\"\n" "$USER_DEFINED_NETWORK"
        fi

        #-Interactive Terminal
        \printf "    USER_DEFINED_INTERACTIVE_TERMINAL=\"%s\"\n" "$USER_DEFINED_INTERACTIVE_TERMINAL"

        #-STARTUP SCRIPT
        if [[ ! -z "$USER_DEFINED_STARTUP_SCRIPT" ]]; then
            \printf "    USER_DEFINED_STARTUP_SCRIPT=\"%s\"\n" "$USER_DEFINED_STARTUP_SCRIPT"
        fi


        clear_space
        print_line_separator
        clear_space

        return 0


}


manage_device_mounting(){

    
    local index_specifier=$INDEX_SPECIFIER

    if [[ ${#USER_DEFINED_DEVICES[@]} -lt $index_specifier ]]; then

        DEVICE_ARGS=()
        return 0
    
    fi

    DEVICE_ARGS=()

    for device in "${USER_DEFINED_DEVICES[@]}"; do

        if [[ ! -z "$device" ]]; then

            DEVICE_ARGS+=("--device" "$device" )

            
        fi


    done

    return 0


}


get_current_env(){



    if [[ ! -e "$CACHE_DIR/podboi_env" ]]; then

        \printf "[ERROR] The Environment Cache file doesn't exist currently"
        return 15
    
    fi

    
    . "$CACHE_DIR/podboi_env"


    if [[ -z "$PODBOI_CURRENT_ENV"  ]]; then

        \printf "\n\nNo Environment is currently selected!\n\n"
        return 0

    fi
        
    
    \printf "%s" "$PODBOI_CURRENT_ENV"
    return 0

}




source_set_env_vars(){

    . "$SCRIPTS_DIR/set_env_vars.sh" || return "$?"

}

source_env_vars(){

    
    . "$CACHE_DIR/podboi_env" || {
        \printf "\n[ERROR] an error occured sourcing %s/podboi_env\n\n" "$CACHE_DIR";
        \printf "
        This error can occur if you manually/accidentally delete the .cache file that determines the Environment\n
        You can create a new environment to restore it, or manually create it - the location should be shown above!\n
        "
        return 15;
    }

    
    if [[ ! -z "$PODBOI_CURRENT_ENV" ]]; then
        
        . "$LOCAL_DIR/$PODBOI_CURRENT_ENV" || {
            \printf "\n[ERROR] an error occured sourcing the %s/%s\n\n" "$LOCAL_DIR" "$PODBOI_CURRENT_ENV";
            \printf "This error can occur if you deleted your environment-state file, or manually changed the environment in the .cache_podboi/podboi_env file!\n\n"
            return 15;
        }
    fi




}

restore_default_working_config(){


    local default_working_config_file="$SCRIPTS_DIR/default_working_config.sh"
    local config_dir="$CONFIG_DIR"

    if [[ ! -d "$config_dir" ]]; then
    
        \mkdir -p "$config_dir" || {
            \printf "\n[ERROR] An error occured running 'mkdir %s'\n\n" "$config_dir"
            return 16
            }

    fi

    \cp "$default_working_config_file" "$CONFIG_DIR/config.sh" || {
        \printf "\n[ERROR] There was an error running command 'cp %s %s' - Check permissions, and create manually!\n\n" "$default_working_config_file" "$CONFIG_DIR/config.sh"
        return 16
        }

    \printf "\nThe Config file has been successfully restored!"
    return 0


}


usage(){

    # Ok, will need to add more when Pod stuff is implemented - this is ChatGPT generated, so.. it's not exactly a piece of art, but I cannot be assed rn to do it myself
    clear_space
    print_line_separator
    clear_space

    \printf "PodBOI - Podman Bash Orchestration Infra Tool\n"
    \printf "===========================================\n\n"

    \printf "CORE CONCEPT\n"
    \printf "  - Everything is grouped by LABEL\n"
    \printf "  - Containers are auto-named: <label>_<id>\n"
    \printf "  - Pods are optional grouping layer\n\n"

    \printf "USAGE:\n"
    \printf "  podboi [COMMAND] [ARGS]\n\n"

    ### GENERAL ###
    \printf "[GENERAL]\n"
    \printf "  %-40s %s\n" "-h, --help" "Show this help"
    \printf "  %-40s %s\n" "--restore-default-config" "Reset config"
    \printf "  %-40s %s\n" "--get-env" "Show current environment"
    \printf "  %-40s %s\n" "--switch-env <env>" "Switch environment"
    \printf "  %-40s %s\n" "--env <env> <cmd>" "Run command in temporary env"
    \printf "  %-40s %s\n" "--is-root" "Displays current Rootful/Rootless status"
    \printf "  %-40s %s\n" "--print-env-vars" "Prints the vars of the current environment to the terminal"



    ### CONTAINERS ###
    \printf "\n[CONTAINERS]\n"
    \printf "  %-40s %s\n" "-c, --create [--config]" "Create containers"
    \printf "  %-40s %s\n" "--start <name|all>" "Start containers"
    \printf "  %-40s %s\n" "--stop <name|all>" "Stop containers"
    \printf "  %-40s %s\n" "--kill <name|all>" "Force stop containers"
    \printf "  %-40s %s\n" "--remove <name|all>" "Remove containers"
    \printf "  %-40s %s\n" "--full-prune" "Kill + remove all in env"

    ### INTERACTION ###
    \printf "\n[INTERACTION]\n"
    \printf "  %-40s %s\n" "--exec <name|all> <cmd>" "Execute command"
    \printf "  %-40s %s\n" "--copy <name|all> <src> <dst>" "Copy files"
    \printf "  %-40s %s\n" "-a, --attach <name>" "Attach shell"

    ### INFO ###
    \printf "\n[INFO]\n"
    \printf "  %-40s %s\n" "-dc, --display-containers" "List all PodBOI Managed containers"
    \printf "  %-40s %s\n" "-ec" "Print container IDs only"

    ### PODS ###
    \printf "\n[PODS]\n"
    \printf "  %-40s %s\n" "--pod-start <name>" "Start pod"
    \printf "  %-40s %s\n" "--pod-stop <name>" "Stop pod"
    \printf "  %-40s %s\n" "--pod-remove <name>" "Remove pod"
    \printf "  %-40s %s\n" "--pod-status <name>" "Show pod status"
    \printf "  %-40s %s\n" "--pod-display" "Show all PodBOI Managed pods"

    ### EXAMPLES ###
    \printf "\n[EXAMPLES]\n"
    \printf "  %-40s %s\n" "podboi -c" "Create default env"
    \printf "  %-40s %s\n" "podboi --start all" "Start all containers"
    \printf "  %-40s %s\n" "podboi --exec all bash" "Exec in all"
    \printf "  %-40s %s\n" "podboi --copy all a b" "Copy to all"
    \printf "  %-40s %s\n" "podboi --env dev --exec all ls" "Run in temp env"

    ### NOTES ###
    \printf "\n[NOTES]\n"
    \printf "  - Labels isolate environments\n"
    \printf "  - Rootful and rootless are separate states\n"
    \printf "  - Pods are optional grouping layer\n"

    clear_space
    print_line_separator
    clear_space


}



get_current_root_status(){


    source_env_vars || return "$?"

    case "$USER_DEFINED_ROOTFUL" in 
    
        true) 

            \printf "\nYou are Rootful\n\n"
            return 0

        ;;

        false)

            \printf "\nYou are Rootless\n\n"
            return 0

        ;;

        *)

            \printf "\n[ERROR] You are neither Rootful nor Rootless, so clearly something's wrong!
                You are probably just in an undefined environment - you can change with --switch-env\n\n"
            return  32

        ;;

    esac

}


#### Container Functions ####

existing_containers(){

    source_env_vars || return "$?"
    escalate_root_privilege || return "$?"
    source_global_commands || return "$?"

    local get_containers_by_label=("${GET_CONTAINERS_BY_LABEL[@]}")


    get_containers_by_label+=("--filter" "label=$PODBOI_CURRENT_ENV")
    "${get_containers_by_label[@]}"

    return 0


}



check_for_existing_containers(){


    local existing_containers_count=$(existing_containers| wc -l)


    if [[ $existing_containers_count -gt 0 ]]; then

        \printf "\n
            [ERROR] There is already an existing PodBOI instance of the same Label!

            Please Stop and Remove these containers in order to create a new instance!\n\n
            "


        return 33

    fi

    return 0


}


display_containers(){



    source_env_vars
    escalate_root_privilege || return "$?"
    source_global_commands || return "$?"

    clear_space

    local _display_containers=("${DISPLAY_CONTAINERS[@]}")

    "${_display_containers[@]}" || { 
        \printf "\n[ERROR] has occured Displaying Containers!\n\n"; 
        return 6; 
        }
    
    clear_space

    return 0

}



containers_is_running(){



    source_env_vars || return "$?"
    escalate_root_privilege || return "$?"
    source_global_commands || return "$?"


    local index_specifier=$INDEX_SPECIFIER
    local args=("$@")

    local state="${args[index_specifier]}"
    local container_name="${args[index_specifier+1]}"

    local _inspect_container=("${INSPECT_CONTAINER[@]}")

    local is_running
    is_running="$("${_inspect_container[@]}" "$container_name")"


    case "$state" in 

        true)

            if [[ "$is_running" == *true* ]]; then

                return 0
            
            fi
            
            return 1

        ;;

        false)

            if [[ "$is_running" == *false* ]]; then

                return 0
            
            fi
            
            return 1

        ;;

        *)

            \printf "\n[ERROR] Invalid variable assignment - expected true/false\n\n"
            return 32

        ;;

    esac

}


stop_containers(){



    source_env_vars || return "$?"
    escalate_root_privilege || return "$?"
    source_global_commands || return "$?"


    local args=("$@")
    local index_specifier=$INDEX_SPECIFIER
    local _stop_container=("${STOP_CONTAINER[@]}")
    

    case "${args[index_specifier]}" in 

        all)

        # ---- STOP ALL ---- #

            local args=("${args[@]:1}")

            local containers=()
            mapfile -t containers < <(existing_containers)


            print_line_separator
            \printf "\n\n[STOP] Stopping all containers in %s\n" "$USER_DEFINED_LABEL" 
            print_line_separator
            clear_space

            for container_name in "${containers[@]}"; do

                if containers_is_running true "$container_name"; then

                    \printf "[STOP] Stopping container %s" "$container_name"

                    "${_stop_container[@]}" "$container_name" || {
                        \printf "\n[ERROR] an error occured stopping the container %s\n\n" "$container_name"
                    }

                    \printf "[SUCCESS]\n\n"

                else

                    \printf "\n[WARNING] Container %s is already not running\n\n" "$container_name"

                fi

            done

        ;;

        *)
            
        # ---- STOP INDIVIDUAL ---- #

            local container_name="${args[index_specifier]}"

            if containers_is_running true "$container_name"; then

                \printf "\n[STOP] Stopping container %s" "$container_name"

                "${_stop_container[@]}" "$container_name" || {
                    \printf "\n[ERROR] an error occured stopping the container %s\n\n" "$container_name"
                    return 7
                }

                \printf "[SUCCESS]\n\n"
                return 0

            else

                \printf "\n[WARNING] Container %s is already not running\n\n" "$container_name"
                return 0

            fi

        ;;

    esac


}



kill_containers(){


    source_env_vars || return "$?"
    escalate_root_privilege || return "$?"
    source_global_commands || return "$?"


    local args=("$@")
    local index_specifier=$INDEX_SPECIFIER
    local _kill_container=("${KILL_CONTAINER[@]}")



    case "${args[index_specifier]}" in 

        all)

            # ---- KILL ALL ---- #

            local args=("${args[@]:1}")

            local containers=()
            mapfile -t containers < <(existing_containers)

            print_line_separator
            \printf "\n\n[KILL] Killing all containers in %s\n" "$USER_DEFINED_LABEL" 
            print_line_separator
            clear_space

            for container_name in "${containers[@]}"; do

                if containers_is_running true "$container_name"; then

                    \printf "[KILL] container %s" "$container_name"

                    "${_kill_container[@]}" "$container_name" || {
                        \printf "\n[ERROR] an error occured killing the container %s\n\n" "$container_name"
                    }

                    \printf "[SUCCESS]\n\n"

                else

                    \printf "\n[WARNING] Container %s is already not running\n\n" "$container_name"

                fi

            done

        ;;

        *)
            
        # ---- KILL INDIVIDUAL ---- #

            local container_name="${args[index_specifier]}"

            if containers_is_running true "$container_name"; then

                \printf "\n[KILL] container %s" "$container_name"

                "${_kill_container[@]}" "$container_name" || {
                    \printf "\n[ERROR] an error occured killing the container %s\n\n" "$container_name"
                    return 8
                }

                \printf "[SUCCESS]\n\n"
                return 0

            else

                \printf "\n[WARNING] Container %s is already not running\n\n" "$container_name"
                return 0

            fi

        ;;

    esac

}



remove_containers(){


    source_env_vars || return "$?"
    escalate_root_privilege || return "$?"
    source_global_commands || return "$?"

    local log_failures=$(mktemp)

    trap 'rm -f "$log_failures"' INT TERM EXIT


    local args=("$@")
    local _remove_container=("${REMOVE_CONTAINER[@]}")
    local index_specifier=$INDEX_SPECIFIER



    case "${args[index_specifier]}" in 

        all)

        # ---- REMOVE ALL ---- #


            local args=("${args[@]:1}")

            local containers=()
            mapfile -t containers < <(existing_containers)

            print_line_separator
            \printf "\n\n[REMOVE] Removing all containers in %s\n" "$USER_DEFINED_LABEL" 
            print_line_separator
            clear_space

            for container_name in "${containers[@]}"; do

                if containers_is_running false "$container_name"; then

                    \printf "[REMOVE] container %s" "$container_name"

                    "${_remove_container[@]}" "$container_name" || {
                        \printf "\n[ERROR] an error occured removing the container %s\n\n" "$container_name"
                    }

                    \printf "[SUCCESS]\n\n"

                else

                    #Output to terminal, then output to log_failure - then I dont have to rely on extra dependancy like tee
                    \printf "\n[FAILURE] A Running container cannot be removed - %s\n\n" "$container_name"
                    \printf "\n[FAILURE] A Running container cannot be removed - %s\n\n" "$container_name" >> "$log_failures"


                fi

            done


            # --- LOG SECTION ---- #
            # [NOTE] make sure to google this, I think -s searches if not empty, but possibly a regular file or some shit
            # - so dunno if it will work with a mktemp
            # - or I could just read the Man Page... nah
            # -- Man page: "-s file       True if file exists and has a size greater than zero."
            # --- but I need to do this cuz it's a fkn nightmare when dealing with 1000+ containers - terminal only has so much space
            # - Read lines - get a line count, printf them - if more than 40 failures, then less the output.... 
            # -- every terminal has to have less, how can anyone function elsewise
            # --- so dependencies are now wc, less, lsof (but not really, it's just better to have it)
            if [[ -s "$log_failures" ]]; then
                
                local line_count
                line_count=$(wc -l < "$log_failures")
                
                if [[ "$line_count" -gt 40 ]]; then

                    \less "$log_failures" && return 0 || { 
                        \printf "\n'less' doesnt exist on this system, so you are gonna have to look at it in the terminal;
                        I hope you don't have too many failures, cuz it's gonna look like shit, and you may not be able to see most entries!
                        "
                    }

                fi
                
                clear_space
                print_line_separator
                clear_space
                \printf "[LOG]\n\n"

                
                while IFS= read -r line; do

                    # if line is empty skip
                    [[ -z "$line" ]] && continue

                    \printf "%s\n" "$line"

                done < "$log_failures"

                clear_space

            fi

        ;;

        *)
            
        # ---- REMOVE INDIVIDUAL ---- #

            local container_name="${args[index_specifier]}"

            \printf "\n"

            if containers_is_running false "$container_name"; then

                \printf "\n[REMOVE] container %s" "$container_name"

                "${_remove_container[@]}" "$container_name" || {
                    \printf "\n[ERROR] an error occured removing the container %s\n\n" "$container_name"
                    return 9
                }

                \printf "[SUCCESS]\n\n"
                return 0

            else

                \printf "\n[FAILURE] A Running container cannot be removed - %s\n\n" "$container_name"
                return 0

            fi

        ;;

    esac

}


attach_to_container(){



    source_env_vars || return "$?"
    escalate_root_privilege || return "$?"
    source_global_commands || return "$?"

    local container_name="$1"

    case "$USER_DEFINED_INTERACTIVE_TERMINAL" in

        true)

            \printf "\n[ATTACH] into container %s\n" "$container_name" 


            "${ATTACH_TO_CONTAINER[@]}" "$container_name" || { 
                \printf "\n[ERROR]: an error occured attaching the container %s\n\n" "$container_name"; 
                return 33
                }

            \printf "[SUCCESS]\n\n"


            return 0

        ;;

        false)

            if [[ "$USER_DEFINED_ROOTFUL" == "true" ]]; then

                \printf "\n[WARNING] Running attach on container '%s' that has been started with INTERACTIVE_TERMINAL as false causes hanging - this action is not allowed!" "$container_name"

                \printf "\nIf you really want to go for it, you can use 'podman attach %s' as root... and God bless you!\n\n" "$container_name"
                return 34 

            fi

            \printf "\n[WARNING] Running attach on container '%s' that has been started without INTERACTIVE_TERMINAL as true causes hanging - this action is not allowed!" "$container_name"

            \printf "\nIf you really want to go for it, you can use 'podman attach %s'... and God bless you!\n\n" "$container_name"
            return 34 

        ;;

    esac


}



copy_to_container(){



    source_env_vars || return "$?"
    escalate_root_privilege || return "$?"
    source_global_commands || return "$?"


    local args=("$@")
    local index_specifier=$INDEX_SPECIFIER
    local _copy=("${COPY[@]}")


    #[IMPORTANT] Verify - using case statement for readability
    # - if not running, attempt start - start will fail the command then instead - I believe us DevOps professionals call this "Indempotency or some shit"
    # - don't do logging functionality like the remove, fail on first failure - because then it's more than likely and issue of the User's end
    # - a logging function would just continuously loop through failures - for 1k+ containers, I'd go fkn mental
    # - I will implement the start function to mitigate any potential breakages

    case "${args[index_specifier]}" in 
    
        all) 

            local containers=()
            mapfile -t containers < <(existing_containers)

            # ---- COPY INTO ALL ---- #

            local args=("${args[@]:1}") #I like this better than shift - hopefully it doesn't come back to haunt me in the future
           
            local source="${args[$index_specifier]}"
            local destination="${args[$index_specifier+1]}"

            print_line_separator
            \printf "\n\n[COPY] Copying '%s' to '%s' into all containers in %s\n" "$source" "$destination" "$USER_DEFINED_LABEL" 
            print_line_separator
            clear_space

            for container_name in "${containers[@]}"; do 

                \printf "========================================"
                
                if containers_is_running false "$container_name"; then

                    \printf "\n[WARNING] Container %s is not running - attempting to start it!\n" "$container_name"
                    start_container "$container_name" || return "$?"

                fi

            \printf "\n[COPY] %s into container %s\n" "$source" "$container_name" 

            "${_copy[@]}" "$source" "${container_name}:${destination}" 1>/dev/null || { 
                \printf "\n[ERROR] an error occured copying into the container %s\n\n" "$container_name"; 
                return 11
                }

            \printf "\n[SUCCESS]\n"
            \printf "========================================"

            done

            clear_space
            return 0            

        ;;
    
    esac


    # ---- COPY INTO INDIVIDUAL ---- #

    local container_name="${args[$index_specifier]}"
    local source="${args[$index_specifier+1]}"
    local destination="${args[$index_specifier+2]}"

    if containers_is_running true "$container_name"; then

        \printf "\n[COPY] %s into container %s\n" "$source" "$container_name" 

        "${_copy[@]}" "$source" "${container_name}:${destination}" 1>/dev/null || { 
            \printf "\n[ERROR] an error occured copying into the container %s\n\n" "$container_name"; 
            return 11
            }

        \printf "[SUCCESS]\n\n"

    else

        \printf "\n[FAILURE] Container %s is not running\n\n" "$container_name"

    fi


    return 0


}




start_container(){



    source_env_vars || return "$?"
    escalate_root_privilege || return "$?"
    source_global_commands || return "$?"


    local args=("$@")
    local _start_container=("${START_CONTAINER[@]}")
    local index_specifier=$INDEX_SPECIFIER


    case "${args[index_specifier]}" in 

        all)

        # ---- START ALL ---- #

            local args=("${args[@]:1}")

            local containers=()
            mapfile -t containers < <(existing_containers)


            \printf "\n[START] Starting all containers in %s\n\n" "$USER_DEFINED_LABEL" 


            for container_name in "${containers[@]}"; do

                if containers_is_running false "$container_name"; then

                    \printf "[START] container %s" "$container_name"

                    "${_start_container[@]}" "$container_name" || {
                        \printf "\n[ERROR] an error occured starting the container %s\n\n" "$container_name"
                    }

                    \printf "[SUCCESS]\n\n"

                else

                    \printf "\n[WARNING] Container %s is already running\n\n" "$container_name"

                fi

            done

        ;;

        *)
            
        # ---- START INDIVIDUAL ---- #
            local container_name="${args[index_specifier]}"


            if containers_is_running false "$container_name"; then

                \printf "\n[START] container %s" "$container_name"

                "${_start_container[@]}" "$container_name" || {
                    \printf "\n[ERROR] an error occured starting the container %s\n\n" "$container_name"
                    return 7
                }

                \printf "[SUCCESS]\n\n"
                return 0

            else

                \printf "\n[WARNING] Container %s is already running\n\n" "$container_name"
                return 0

            fi

        ;;

    esac


}


exec_to_container(){


    source_env_vars || return "$?"
    escalate_root_privilege || return "$?"
    source_global_commands || return "$?"


    local args=("$@")
    local index_specifier=$INDEX_SPECIFIER
    local _exec_command=("${EXEC_COMMAND[@]}")


    case "${args[index_specifier]}" in

        all)

            # ---- EXEC INTO ALL ---- #

            \printf "\n[EXEC] Executing command into all containers in %s\n\n" "$USER_DEFINED_LABEL"

            local containers=()
            mapfile -t containers < <(existing_containers)

            local cmd_args=("${args[@]:1}")

            \printf "\n[COMMAND] %s\n\n" "${cmd_args[*]}"


            for container_name in "${containers[@]}"; do

                \printf "========================================"
                if containers_is_running false "$container_name"; then

                    \printf "\n[WARNING] Container %s is not running - attempting to start it!\n\n" "$container_name"
                    start_container "$container_name"

                fi


                \printf "\n[EXEC] '%s' into container %s\n\n" "${cmd_args[*]}" "$container_name"

                "${_exec_command[@]}" "$container_name" "${cmd_args[@]}" || {
                    \printf "\n[ERROR] exec failed in container %s\n\n" "$container_name"; \
                    return 13
                }

                \printf "\n[SUCCESS]\n"
                \printf "========================================"

                clear_space

            done

            return 0

        ;;


        *)
            # ----  EXEC INTO INDIVIDUAL ---- #

            local container_name="${args[$index_specifier]}"
            local cmd_args=("${args[@]:1}")

            \printf "\n[EXEC] '%s' into container %s\n\n" "${cmd_args[*]}" "$container_name"

            "${_exec_command[@]}" "$container_name" "${cmd_args[@]}" || {
                 \printf "\n[ERROR] exec failed in container %s\n\n" "$container_name"; \
                 return 13;

            }

            \printf "[SUCCESS]\n\n"
            return 0
        ;;

    esac

}

create_containers(){


    source_global_commands || return "$?"
    config_and_user_input_validation || return "$?"
    source_set_env_vars || return "$?"

    #Refresh global commands with the values from the current env
    source_global_commands || return "$?"



    manage_volume_mounting
    manage_device_mounting

    clear_space

    create_pod "$USER_DEFINED_POD_NAME" || return "$?"

    local _copy_to_container=("${COPY[@]}")
    local _exec_command_to_container=("${EXEC_COMMAND[@]}")


    local container_number=1
    local container_number_validate=$container_number
    local index_specifier=$INDEX_SPECIFIER

    local _create_container=("${CREATE_CONTAINER[@]}")

    if [[ "$USER_DEFINED_INTERACTIVE_TERMINAL" == "true" ]]; then

        _create_container+=("-it")

    fi

    _create_container+=("--label" "$LABEL_PODBOI")

    if [[ "$USER_DEFINED_POD" == "true" ]]; then

        _create_container+=("--pod" "$USER_DEFINED_POD_NAME")

    else 

        _create_container+=("--network" "$USER_DEFINED_NETWORK")

    fi


    # Quick check to see if the names are free
    # This is for a v specific use-case issue I was having on Bare-Metal Arch, I dont see these issues on Mac

    \printf "\n[VERIFY] Verifying names are not already taken! This may take some time depending on how many containers you wish to run....\n\n"

    local _inspect_container=("${INSPECT_CONTAINER[@]}")

    for ((i = index_specifier; i < USER_DEFINED_NO_OF_CONTAINERS; i++)) do

        local container_name_validate="${USER_DEFINED_LABEL}_${container_number_validate}"

        #This needs to be tested on bare-metal
        #podman inspect the name, if it exists, then exit
        "${_inspect_container[@]}" "$container_name_validate" &>/dev/null
        local check=$?
        
        if [[ $check -eq 0 ]]; then

            \printf "\n[ERROR] The Container '%s' already exists somewhere on your machine, please remove it before proceeding, or change the Label Name to an unused label in your Config\n\n" "$container_name_validate"
            return 27

        fi

        ((container_number_validate++))

    done


    for ((i = index_specifier; i < USER_DEFINED_NO_OF_CONTAINERS; i++)) do

        local random_number=$((RANDOM % ${#USER_DEFINED_IMAGES[@]}))
        local container_image="${USER_DEFINED_IMAGES[$random_number]}"
        local container_name="${USER_DEFINED_LABEL}_${container_number}"


        print_line_separator

        \printf "\n\n[CREATE] container %s\n" "$container_name"


        # ------------------------------------------------------------
        # IMPORTANT FIX:
        # build full command including image first in an array like this instead of just manually building it
        # ------------------------------------------------------------

        local _run_container=("${_create_container[@]}")

        _run_container+=(
            -e "PODBOI_NAME=$container_name"
            -e "PODBOI_LABEL=$USER_DEFINED_LABEL"
            -e "PODBOI_IMAGE=$container_image"
            --label "$USER_DEFINED_LABEL"
            "${VOLUME_ARGS[@]}"
            "${DEVICE_ARGS[@]}"
            --name "$container_name"
        )

        # IMAGE MUST ALWAYS COME BEFORE ANY OPTIONAL COMMANDS
        _run_container+=("$container_image")

        # only use sleep infinity when NOT in pod AND NOT interactive cuz then it stops immediately, and doesn't start
        if [[ "$USER_DEFINED_INTERACTIVE_TERMINAL" == "false" && "$USER_DEFINED_POD" == "false" ]]; then

            _run_container+=(sleep infinity)
        
        fi


        "${_run_container[@]}" 1>/dev/null || {

            \printf "
                [ERROR] An error occured creating the container %s.
                If in a Pod, it could be a used-port conflict, it could be a network issue; or it could be a Keyring-limit issue if you are running many containers.
                Num_lock issues, as well as Network exhaustion could also cause this if your system contains a lot of containers.
                It could also be an issue of the image having the wrong architecture of your system.
                There may be an Error message from Podman left above to help you debug!\n
                " "$container_name"

            "${REMOVE_CONTAINER[@]}" "$container_name" &>/dev/null
            clear_space
            return 25
        }
        
        \printf "[SUCCESS] Creating container %s\n" "$container_name"
    
        #This is where the startup script is set, copied and ran
        if [[ ! -z "$USER_DEFINED_STARTUP_SCRIPT" ]]; then

            # 1) exec mkdir /podboi
            \printf "\n[EXEC] '%s' into container %s\n" "mkdir -p /podboi/" "$container_name"

            "${_exec_command_to_container[@]}" "$container_name" mkdir -p /podboi/ 1>/dev/null \
                && \printf "[SUCCESS]\n" \
                || \printf "[FAILURE]\n"


            # 2) run the startup script
            \printf "\n[COPY] %s into container %s\n" "$USER_DEFINED_STARTUP_SCRIPT" "$container_name"

            "${_copy_to_container[@]}" "$USER_DEFINED_STARTUP_SCRIPT" "$container_name":"/podboi/setup.sh" 1>/dev/null \
                && \printf "[SUCCESS]\n" \
                || \printf "[FAILURE]\n"


            # 3) make sure it's executable in the Container!
            \printf "\n[EXEC] '%s' into container %s\n" "chmod 755 /podboi/setup.sh" "$container_name"

            "${_exec_command_to_container[@]}" "$container_name" chmod 755 /podboi/setup.sh 1>/dev/null \
                && \printf "[SUCCESS]\n" \
                || \printf "[FAILURE]\n"


            # 4) execute the startup script
            \printf "\n[EXEC] the Setup Script in container %s\n" "$container_name"
            \printf "\n================ Startup Script ================\n\n"

            if "${_exec_command_to_container[@]}" "$container_name" /podboi/setup.sh; then 
            
                \printf "\n=================================================\n"
                \printf "\n[SUCCESS] Initializing setup in %s\n" "$container_name"
            
            else
            
                \printf "\n=================================================\n"
                \printf "\n[FAILURE] Initializing setup in %s\n" "$container_name"
            
            fi

        fi


        ((container_number++))

        print_line_separator
        clear_space


    done 

    return 0

}

#### POD Functions ####


check_for_existing_pod(){

    source_env_vars
    escalate_root_privilege || return "$?"
    source_global_commands

    local pod_name="$1"
    local _inspect_pod=("${INSPECT_POD[@]}")

    if "${_inspect_pod[@]}" "$("${ROOT[@]}" podman pod ps -q --filter label=PodBOI.Managed=true --filter name="$pod_name")" &>/dev/null; then

        return 0
    fi

    return 18

}

manage_port_handling(){


    _pod_port_args=()


    for _pod_port in "${USER_DEFINED_POD_PORTS[@]}"; do

	    if [[ ! -z "$_pod_port" ]]; then
			
			_pod_port_args+=("-p" "$_pod_port")
		
        else

            _pod_port_args=()

		fi

	done

    return 0

}



create_pod(){



    if [[ "$USER_DEFINED_POD" != "true" ]]; then

        return 0

    fi

    manage_port_handling

    local pod_name="$1"
    local _create_pod=("${CREATE_POD[@]}" "${_pod_port_args[@]}")

    check_for_existing_pod "$pod_name"

    local check="$?"
        
    case "$check" in

        18)   
            "${_create_pod[@]}" "--name=$pod_name" || {

                \printf "\n\n[ERROR] An issue occured creating the pod '%s'\n\n" "$pod_name";
                clear_space
                return 20;
                }

            return 0
        ;;

        0)
            \printf "\n\n[WARNING] The Pod '%s' already exists\nThis Pod will thus be used\n\n" "$pod_name"
            _create_pod=()
            return 0
        ;;

        *)
            \printf "\n\n[ERROR] An issue occured creating a pod\n\n"
            return 19
        ;;


    esac




}


stop_pod(){



    local pod_name="$1"

    # This will source the Globals and env
    check_for_existing_pod "$pod_name"

    local check="$?"
    local _stop_pod=("${STOP_POD[@]}")
        
    case "$check" in

        18)   
            \printf "\n\n[ERROR] The Pod '%s' doesn't exist under PodBOI!\n\n" "$pod_name";
                clear_space
                return "$check"

        ;;

        0)

            "${_stop_pod[@]}" "$pod_name" || {

            \printf "\n\n[ERROR] An issue occured stopping the pod '%s'\n\n" "$pod_name";
                clear_space
                return 21;
                }

            return 0
        ;;

        *)
            \printf "\n\n[ERROR] An issue occured! Return code invalid!\n\n"
            return 19
        ;;


    esac



}


start_pod(){



    local pod_name="$1"

    check_for_existing_pod "$pod_name"


    local check="$?" 
    local _start_pod=("${START_POD[@]}")


    case "$check" in

        18)   
            \printf "\n\n[ERROR] The Pod '%s' doesn't exist under PodBOI!\n\n" "$pod_name";
            clear_space
            return "$check"

        ;;

        0)
            
            "${_start_pod[@]}" "$pod_name" || {

                \printf "\n\n[ERROR] An issue occured starting the pod '%s'\n\n" "$pod_name";
                clear_space
                return 22;
                }

            return 0
        ;;

        *)
            \printf "\n\n[ERROR] An issue occured! Return code invalid!\n\n"
            return 19
        ;;


    esac



}



remove_pod(){



    local pod_name="$1"


    check_for_existing_pod "$pod_name"

    local check="$?"
    local _remove_pod=("${REMOVE_POD[@]}")

        
        case "$check" in

            18)   
            \printf "\n\n[ERROR] The Pod '%s' doesn't exist under PodBOI!\n\n" "$pod_name";
                clear_space
                return "$check"

            ;;

            0)
                "${_remove_pod[@]}" "$pod_name" || {

                    \printf "\n\n[ERROR] An issue occured removing the pod '%s'\n\n" "$pod_name";
                    clear_space
                    return 23;
                    }

                return 0
            ;;

            
            *)
                \printf "\n\n[ERROR] An issue occured! Return code invalid!\n\n"
                return 19
            ;;


        esac



}


status_of_pod(){



    local pod_name="$1"


    check_for_existing_pod "$pod_name"

    local check="$?"
    local _status_of_pod=("${STATUS_OF_POD[@]}")

        case "$check" in

            18)   
                \printf "\n\n[ERROR] The Pod '%s' doesn't exist under PodBOI!\n\n" "$pod_name";
                clear_space
                return "$check"

            ;;

            0)

                clear_space

                _status_of_pod+=("--filter" "name=$pod_name")
                "${_status_of_pod[@]}" || {

                    \printf "\n\n[ERROR] An issue occured getting the Status of the Pod '%s'\n\n" "$pod_name";
                    clear_space
                    return 24;
                    }

                clear_space

                return 0
            ;;

            *)
                \printf "\n\n[ERROR] An issue occured! Return code invalid!\n\n"
                return 19
            ;;


        esac



}

kill_pod(){


    local pod_name="$1"

    check_for_existing_pod "$pod_name"


    local _kill_pod=("${KILL_POD[@]}")
    local check="$?"
        
        case "$check" in

            18)   
                    \printf "\n\n[ERROR] The Pod '%s' doesn't exist under PodBOI!\n\n" "$pod_name";
                    clear_space
                    return "$check"

            ;;

            0)
                "${_kill_pod[@]}" "$pod_name" || {

                    \printf "\n\n[ERROR] An issue occured killing the pod '%s'\n\n" "$pod_name";
                    clear_space
                    return 21;
                }

                return 0
            ;;

            *)
                \printf "\n\n[ERROR] An issue occured! Return code invalid!\n\n"
                return 19
            ;;


        esac



}



display_pods(){

    source_env_vars
    source_global_commands

    local _display_pods=("${DISPLAY_POD[@]}")

    clear_space
   
    "${_display_pods[@]}"
    
    clear_space
    

    return 0

}

#template_for_pod_operations(){


    #local pod_name="$1"

    #check_for_existing_pod "$pod_name"

    ## this needs to be called here because check_for_existing_pod sources the env/commands
   # local _cmd=("${CMD_POD[@]}")
       # local check="$?"
      #  
     #   case "$check" in

    #        18)   
    #               \printf "\n\n[ERROR] The Pod '%s' doesn't exist under PodBOI!\n\n" "$pod_name";
  #                  clear_space
 #                   return "$check"
#
 #           ;;
#
  #          0)
 #               "$_cmd{[@]}" "$pod_name" || {
#
           #         \printf "\n\n[ERROR] An issue occured xxxx the pod '%s'\n\n" "$pod_name";
          #          clear_space
         #           return xx;
        #        }

       #         return 0
      #      ;;

     #       *)
    #            \printf "\n\n[ERROR] An issue occured! Return code invalid!\n\n"
   #             return 19
  #          ;;


 #       esac



#}
###############


#### Main ####

podboi_main(){


    case "$1" in

        #### CONTAINER FLAGS ####
	    --create | -c)
            
            shift
            
            if [[ "$1" == "--config" ]]; then

                shift
            
                if (( $# > 1 )); then
                    \printf "\n[ERROR] Invalid number of args!\n\n"
                    return 14
                fi

                CONFIG_FILE="$1"

            else

            if (( $# != 0 )); then
                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi

                #Default Config File - can be changed during --create!
                CONFIG_FILE="$CONFIG_DIR/config.sh"

            fi

            create_containers || return "$?"
        
        ;;

        --exec)

            shift

            if (( $# < 2 )); then
                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi

            exec_to_container "$@" || return "$?"

        ;;

        --copy)

            shift

            if (( $# != 3 )); then
                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi
        
            copy_to_container "$@" || return "$?"

        ;;

        --start)

        
            shift

            if (( $# != 1 )); then
                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi
        
            start_container "$@" || return "$?"

        ;;

        --stop)

            shift

            if (( $# != 1 )); then
                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi

            stop_containers "$@" || return "$?"
        
        ;;

        --kill)
            
            shift

            if (( $# != 1 )); then
                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi
            
            kill_containers "$@" || return "$?"
        ;;

        --remove)
            
            shift

            if (( $# != 1 )); then
                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi
            
            remove_containers "$@" || return "$?"
        ;;

        --display-containers | -dc)
            
            shift

            if (( $# != 0 )); then
                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi

            display_containers || return "$?"

        ;;

        --full-prune | -fp)
           
            shift
           
            if (( $# != 1 )); then

                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi

            kill_containers "$@" || return "$?"
            remove_containers "$@" || return "$?"
        ;;

        --attach | -a)

            shift

            if [[ $# -ne 1 ]]; then

                \printf "\n\n[ERROR] Invalid number of args!\n\n"
                return 14

            fi

            attach_to_container "$1" || return "$?"


        ;;

        --switch-env)

            shift

            if [[ $# -ne 1 ]]; then

                \printf "\n\n[ERROR] Invalid number of args!\n\n"
                return 14

            fi

            switch_environment --switch "$1" || return "$?"

        ;;

        --print-env-vars)

            shift

            if [[ $# -ne 0 ]]; then

                \printf "\n\n[ERROR] Invalid number of args!\n\n"
                return 14

            fi

            print_env_vars

        ;;

        --env)
            # quick switch into env to perform a command, then return to current env
            shift

            # keep the var names with _ prefix, this is something I just learned about and can barely explain it - it could be a cause of issues
            #   - but it saves me re-writing a lot of shite
            local _target_env="$1"
            local _current_env=$(get_current_env)
            
            shift

            if [[ -z "$_target_env" ]]; then
                \printf "\n[ERROR] No environment specified for --env\n\n"
                return 17
            fi

            if [[ $# -eq 0 ]]; then
                \printf "\n[ERROR] No command provided after --env\n\n"
                return 14
            fi

            (
                # switch inside subshell, then I can delete the temp switch functionality, just perform like this - avoid re-writing existing_containers
                switch_environment --switch "$_target_env" || exit "$?"

                # this should fix the variable issues
                source_env_vars || exit "$?"

                # re-run the main function so --exec etc can be run as normal
                #-if --create then no.... didnt fkn think of this one now, did I?
                #-ok so if $1 is --copy --exec --stop --start --remove --kill --attach --full-prune -ec
                #--then proceed, else usage maybe! actually no, bad idea to use usage, just make a list or some shit
                # try create 3 envs, the keep switching them until finally exec a command just to see 
                ##if $1 here, then cancel
                ## exits in here, get rid of that subshell issue when passing returns
                local _allowed=(
                    --exec 
                    --copy 
                    --start 
                    --stop
                    --remove 
                    --kill 
                    --attach 
                    --full-prune 
                    -ec
                    --print-env-vars
                )

                local _cmd="$1"
                local _valid=false

                for _opt in "${_allowed[@]}"; do
                    if [[ "$_opt" == "$_cmd" ]]; then
                        _valid=true
                        break
                    fi
                done

                if [[ "$_valid" = false ]]; then
                    
                    \printf "
                        
                        [ERROR] Commands supported using the --env function are:

                            %s

            
                    " "${_allowed[*]}"

                    \printf "\n"
            
                    exit 14
            
                fi


                podboi_main "$@"

                execution_status=$?


                # then switch back to the prior env
                switch_environment --switch "$_current_env" || exit $?

                exit "$execution_status"

            )

            return "$?"

        ;;

        --get-env)

            shift

            if [[ $# -ne 0 ]]; then

                \printf "\n\n[ERROR] Invalid number of args!\n\n"
                return 14

            fi

            \printf "\nYour current environment is: "
            get_current_env || return "$?"
            clear_space

        ;;

        --restore-default-config)

            shift

            if [[ $# -ne 1 ]]; then

                \printf "\n\n[ERROR] Invalid number of args!\n\n"
                return 14

            fi

            restore_default_working_config
            clear_space

        ;;

        #### POD FLAGS ####

        --pod-remove)
        
            shift

            if (( $# != 1 )); then
                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi

            remove_pod "$@" || return "$?"
        
        ;;

        --pod-kill)
        
            shift

            if (( $# != 1 )); then
                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi

            kill_pod "$@" || return "$?"
        
        ;;

        --pod-stop)
    
            shift

            if (( $# != 1 )); then
                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi    
        
            stop_pod "$@" || return "$?"

        ;;

        --pod-start)
        
            shift

            if (( $# != 1 )); then
                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14
            fi        
        
            start_pod "$@"|| return "$?"

        ;;

        --pod-display)

            shift

            if (($# != 0)); then

            \printf "[ERROR] Invalid number of args!\n\n"
            return 14

            fi

            display_pods || return "$?"

        ;;

        --pod-status)
        
            shift

            if (( $# != 1 )); then

                \printf "\n[ERROR] Invalid number of args!\n\n"
                return 14

            fi

            status_of_pod "$@" || return "$?"


        ;;

        #### OTHERS ####
        #prints the current environments containers quietly by id
        -ec)

            shift

            if (($# != 0)); then

            \printf "[ERROR] Invalid number of args!\n\n"
            return 14

            fi

            existing_containers || return "$?"

        ;;

        --is-root)

            shift

            if (($# != 0)); then

                \printf "[ERROR] Invalid number of args!\n\n"
                return 14

            fi

            get_current_root_status || return "$?"

        ;;

        -h | --help)

            usage

        ;;

        *)

            \printf "\n\nThis is an invalid arg\n\n"
            usage
            return 14

        ;;

    esac

}

podboi_main "$@"