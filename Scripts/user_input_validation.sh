#!/usr/bin/env bash


if [ -n "$BASH_VERSION" ]; then
    SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
elif [ -n "$ZSH_VERSION" ]; then
    SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
fi



############## User Input Validation Section ##############

user_input_rootful_choice(){


	local max_input_attempts=0
	local user_input_rootful


	\printf "\nUsage: <empty> for Defaults set in the Config | 'true' if rootful! | 'false' if not rootful!\n\n"

	while ((max_input_attempts < 3)); do


		"${READ_COMMAND[@]}" "Do you want to run Rootful? " user_input_rootful || { 
            \printf "\nError taking User Input\n"; 
            return 2; 
            }

		if [[ -z "$user_input_rootful" ]]; then

			\printf "\nDefault chosen: %s!" "$ROOTFUL"
			USER_DEFINED_ROOTFUL="$ROOTFUL"
			return 0

        fi

		case "$user_input_rootful" in

			"true")
                
                USER_DEFINED_ROOTFUL="$user_input_rootful"
                local root=()

                #check for current privilege status
                if [[ "$EUID" -eq 0 ]]; then 

                    ROOT=()
                    return 0

                fi

                #test for sudo or doas
                if command -v sudo >/dev/null 2>&1; then
                    
                    root=("sudo")
                    ROOT=("${root[@]}")
                    return 0

                elif command -v doas >/dev/null 2>&1; then

                    root=("doas")
                    ROOT=("${root[@]}")
                    return 0
                fi

                \printf "\n[ERROR] Neither sudo nor doas is available!\n"
                return 2

            ;;

            "false")
                
                USER_DEFINED_ROOTFUL="$user_input_rootful"
                ROOT=()
                return 0

            ;;

            *) 

                \printf "\n[ERROR] Invalid input:"
                ((max_input_attempts++))
                \printf "\nAttempt %d of 3 failed.\n\n" "$max_input_attempts"

            ;;

        esac


	done

	\printf "\nMax number of failed attempts reached, exiting now!\n\n"
	return 2


}


user_input_pod_choice(){



	local max_input_attempts=0
	local pod


	\printf "\nUsage: <empty> for Defaults set in the Config | 'true' if you want a Pod! | 'false' if no Pod!\n\n"

	while ((max_input_attempts < 3)); do

		
		"${READ_COMMAND[@]}" "Do you want to use a Pod? " pod || { 
            \printf "\nError taking User Input\n"; 
            return 2; 
            }

		if [[ -z "$pod" ]]; then

			\printf "\nDefault chosen: %s!" "$POD"
			USER_DEFINED_POD="$POD"
			return 0

        fi

		case "$pod" in

			"true")
                
                USER_DEFINED_POD="$pod"
                return 0

            ;;

            "false")
                
                USER_DEFINED_POD="$pod"
                return 0

            ;;

            *) 

                \printf "\n[ERROR] Invalid input\n\n"
                ((max_input_attempts++))
                \printf "\nAttempt %d of 3 failed.\n\n" "$max_input_attempts"

            ;;

        esac


	done


	\printf "\nMax number of failed attempts reached, exiting now!\n\n"
	return 2


}



user_input_pod_name_choice(){


    local max_input_attempts=0
    local pod_name
    user_defined_pod_exists="false"

    \printf "\nUsage: <empty> for Defaults set in the Config | '<Pod Name>' for the name of the Pod that you wish to use\n\n"

	while ((max_input_attempts < 3)); do

		
		"${READ_COMMAND[@]}" "Enter the Name of the Pod you wish to use/create: " pod_name || { 
            \printf "\nError taking User Input\n"; 
            return 2; 
            }

		if [[ -z "$pod_name" ]]; then

			\printf "\nDefault chosen: %s!" "$POD_NAME"
			USER_DEFINED_POD_NAME="$POD_NAME"
            return 0

        fi


        USER_DEFINED_POD_NAME="$pod_name"


        # if pod exists, then warn, display info, variable user_defined_pod_exists=true, sleep 7
        if "${ROOT[@]}" podman pod exists "$USER_DEFINED_POD_NAME" &>/dev/null; then

		    local _pod_info
            _pod_info="$("${ROOT[@]}" podman pod inspect "$USER_DEFINED_POD_NAME" 2>/dev/null | head -n 13 | tail -n 11)"

		    \printf "\n
			    [WARNING] The Pod %s exists and will thus be used.  If you do not wish to use this Pod, you should cancel with [ctrl + c] or [ctrl + d]\n
			    If SKIP_RUNTIME_CHANGES is set to false, you can change during the Runtime Changes section\n
			    Below will be information about the selected Pod's Ports so you may avoid clashes\n
			    " "$USER_DEFINED_POD_NAME"

		    clear_space
		    \printf "%s" "$_pod_info"
		    clear_space

		    sleep 7

            user_defined_pod_exists="true"
		    USER_DEFINED_POD_PORTS=()

		    return 0

        else

            return 0

	    fi

	done


	\printf "\nMax number of failed attempts reached, exiting now!\n\n"
	return 2


}


user_input_pod_port_choice(){


    # if pod already exists, then skip
    if [[ "$user_defined_pod_exists" == "true" ]]; then

        return 0

    fi


    local max_input_attempts=0
    local pod_ports=()


    \printf "\nUsage: <empty> for Defaults set in the Config | '<HOST_PORT>:<CONTAINER_PORT>' for the Ports of the Pod that you wish to use\n\n"

    while ((max_input_attempts < 3)); do

        "${READ_COMMAND[@]}" "Enter the Name of the Pod's Ports you wish to use: " "${READ_COMMAND_ARRAY_FLAG[@]}" pod_ports || { 
            \printf "\nError taking User Input\n"; 
            return 2; 
            }
        
        if (( ${#pod_ports[@]} == 0 )); then

            
            \printf "\nDefault chosen: %s!" "${POD_PORTS[*]}"
            USER_DEFINED_POD_PORTS=("${POD_PORTS[@]}")
            return 0

        fi


        local all_valid="true"


        for pod_port in "${pod_ports[@]}"; do

            # validate format
            if [[ ! "$pod_port" =~ ^[0-9]+:[0-9]+$ ]]; then

                \printf "\n[ERROR] %s is not in valid HOST:CONTAINER format!\n" "$pod_port"
                all_valid="false"
                continue

            fi


            local host_port="${pod_port%%:*}"


            # validate port range
            if (( host_port < 1 || host_port > 65535 )); then

                \printf "\n[ERROR] %s is not a valid host port!\n" "$host_port"
                all_valid="false"
                continue

            fi


	        # if lsof doesn't exist, allow to pass, and this should hopefully be caught during creation time
		    # - allows less dependencies, and user's without lsof will be able to continue
		    if ! command -V lsof &> /dev/null; then

			    continue

		    fi


            # check if host port already in use
            if \lsof -i :"$host_port" &>/dev/null; then

                \printf "\n[ERROR] Host Port %s is already in use!\n\n" "$host_port"
                all_valid="false"

            fi

        done


        if [[ "$all_valid" == "true" ]]; then

            USER_DEFINED_POD_PORTS=("${pod_ports[@]}")
            return 0

        fi


        ((max_input_attempts++))
        \printf "\nAttempt %d of 3 failed.\n\n" "$max_input_attempts"

    done

    \printf "\nMax number of failed attempts reached, exiting now!\n\n"
    return 2

}



#Create a quick Pod create test to make sure all is valid before heading into the rest, else user can retry again
_user_pod_choice_validation_check(){


    if [[ "$USER_DEFINED_POD" == "false" ]]; then

        return 0

    fi

    if [[ "$user_defined_pod_exists" == "true" ]]; then 

        return 0

    fi
    

    local pod_name="$USER_DEFINED_POD_NAME"


    # validate pod name is non-empty
    if [[ -z "$pod_name" ]]; then

        \printf "\n[ERROR] Pod name can not be empty!\n\n"
        return 2

    fi


    # validate pod does not already exist
    if "${ROOT[@]}" podman pod exists "$pod_name" &>/dev/null; then

        \printf "\n[ERROR] Pod %s already exists!\n\n" "$pod_name"
        return 2

    fi


    # validate ports are unique - i dont like nested stuff like this [REVISIT]
    local seen_ports=()

    for pod_port in "${USER_DEFINED_POD_PORTS[@]}"; do

        local host_port="${pod_port%%:*}"


        for seen_port in "${seen_ports[@]}"; do

            if [[ "$host_port" == "$seen_port" ]]; then

                \printf "\n[ERROR] Duplicate host port detected: %s\n
                The Pod will fail on creation, retry again, but please... next time, make no mistakes!\n" "$host_port"
                return 30
            fi

        done


        seen_ports+=("$host_port")

    done


	clear_space
	return 0


}



user_input_label_choice(){

    local max_input_attempts=0
    local label

    \printf "\nUsage: <empty> for Defaults set in the Config | '<label name>' for the label you wish to use\n\n"

    while ((max_input_attempts < 3)); do

        "${READ_COMMAND[@]}" "Do you want to use another label? " label || { 
            \printf "\nError taking User Input\n"; 
            return 2; 
        }

        if [[ -z "$label" ]]; then

            USER_DEFINED_LABEL="$LABEL"
            \printf "\nDefault Label chosen: %s" "$LABEL"
            return 0

        fi


        if [[ ! "$label" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then

            \printf "\n[ERROR] 'LABEL' can not contain a space nor certain characters!\n\n"
            ((max_input_attempts++))
            \printf "\nAttempt %d of 3 failed.\n" "$max_input_attempts"
            continue

        fi


        local get_containers_by_label=("${GET_CONTAINERS_BY_LABEL[@]}")
        get_containers_by_label+=("--filter" "label=$label")

        local check_label_exists
        check_label_exists=$("${get_containers_by_label[@]}" | wc -l)


        if (( check_label_exists > 0 )); then

            \printf "\n[ERROR] This Label already exists with running containers!\n\n"
            ((max_input_attempts++))
            \printf "\nAttempt %d of 3 failed.\n" "$max_input_attempts"
            continue

        fi


        USER_DEFINED_LABEL="$label"
        return 0

    done

    \printf "\nMax number of failed attempts reached, exiting now!\n\n"
    return 2


}


user_input_no_of_containers(){



    #get: how many containers; image/random; network; no_volumes; volume mount points; startup_script    
    
    local max_input_attempts=0
	local no_of_containers=1


    #Take num of containers	
    while ((max_input_attempts < 3)); do

        
    	"${READ_COMMAND[@]}" "How many containers do you want? (Default is set to $NO_OF_CONTAINERS): " no_of_containers || { 
            \printf "\nError taking User Input!\n\n"; 
            return 2; 
            }

	    if [[ -z "$no_of_containers" ]]; then

            USER_DEFINED_NO_OF_CONTAINERS=$NO_OF_CONTAINERS
		    \printf "\nDefault number of containers chosen: %s" "$NO_OF_CONTAINERS"
			return 0

	    fi


	    if [[ ! "$no_of_containers" =~ ^[1-9][0-9]*$ ]]; then

	        \printf "\nThat is not a valid number\n"	

	        ((max_input_attempts++))
			\printf "\nAttempt %d of 3 failed.\n" "$max_input_attempts"


        else

            USER_DEFINED_NO_OF_CONTAINERS=$no_of_containers
	        return 0

        fi

    done


	\printf "Max number of failed attempts reached, exiting now!\n\n"
	return 2


}


    
user_input_image_choice() {


    local max_input_attempts=0
    local user_input_images=()


    \printf "\nUsage: '<Image>' or multiple like 'ubuntu archlinux'\n"

    while (( max_input_attempts < 3 )); do

		local all_valid="true"


        "${READ_COMMAND[@]}" "What image/images do you wish to use? " "${READ_COMMAND_ARRAY_FLAG[@]}" user_input_image || 
        { 
            \printf "\nError taking User Input!\n\n"; 
            return 2; 
            }

        if [[ ${#user_input_image[@]} -eq 0 ]]; then
            
			USER_DEFINED_IMAGES=("${IMAGES[@]}")
            \printf "\n\nDefault Images chosen: %s\n\n" "${IMAGES[*]}"
            return 0
        
		fi

        # Reset before validating
        USER_DEFINED_IMAGES=()

        for user_input_image in "${user_input_images[@]}"; do

            if "${ROOT[@]}" podman image inspect "$user_input_image" &>/dev/null || "${ROOT[@]}" podman manifest inspect "$user_input_image" &>/dev/null; then
                
				USER_DEFINED_IMAGES+=("$user_input_image")
            
			else
            
			    \printf "\n[ERROR] %s is not an available Image!\n" "$user_input_image"
                all_valid="false"
            
			fi

        done


        if [[ "$all_valid" == "true" ]]; then
      
	        return 0
       
	    fi

        ((max_input_attempts++))
        \printf "\nAttempt %d of 3 failed.\n\n" "$max_input_attempts"

    done

    \printf "\nMax number of failed attempts reached, exiting now!\n\n"
    return 2

}


user_input_interactive_terminal_choice(){


    local max_input_attempts=0
    local interactive_terminal


    \printf "\nUsage: <empty> for Defaults set in the Config | 'true' if you want a Pod! | 'false' if no Pod!\n\n"

	while ((max_input_attempts < 3)); do

		
		"${READ_COMMAND[@]}" "Do you want to use an Interactive Terminal? " interactive_terminal || { 
            \printf "\nError taking User Input\n"; 
            return 2; 
            }

		if [[ -z "$interactive_terminal" ]]; then

			\printf "\nDefault chosen: %s!" "$INTERACTIVE_TERMINAL"
			USER_DEFINED_INTERACTIVE_TERMINAL="$INTERACTIVE_TERMINAL"
			return 0

        fi

		case "$interactive_terminal" in

			"true")
                
                USER_DEFINED_INTERACTIVE_TERMINAL="$interactive_terminal"
                return 0

            ;;

            "false")
                
                USER_DEFINED_INTERACTIVE_TERMINAL="$interactive_terminal"
                return 0

            ;;

            *) 

                \printf "\n[ERROR] Invalid input\n\n"
                ((max_input_attempts++))
                \printf "\nAttempt %d of 3 failed.\n\n" "$max_input_attempts"

            ;;

        esac


	done


	\printf "\nMax number of failed attempts reached, exiting now!\n\n"
	return 2


}


user_input_network_choice(){


    local max_input_attempts=0
	local network


    while ((max_input_attempts < 3)); do

        
    	"${READ_COMMAND[@]}"  "What Network do you want? (Default is set to $NETWORK): " network || { 
            \printf "\nError taking User Input!\n\n"; 
            return 2; 
            }

	    if [[ -z "$network" ]]; then

            USER_DEFINED_NETWORK="$NETWORK"
		    \printf "\nDefault Network chosen: %s" "$NETWORK"
			return 0

	    fi



	    # Don't rely on podman create for validation - it mutates state
	    if ! "${ROOT[@]}" podman network inspect "$network" &>/dev/null; then

	        \printf "\nThat is not a valid Network\n"	

	        ((max_input_attempts++))
	        \printf "\nAttempt %d of 3 failed.\n" "$max_input_attempts"


        else

            USER_DEFINED_NETWORK="$network"
	        return 0

        fi

    done


	\printf "Max number of failed attempts reached, exiting now!\n\n"
	return 2



}



user_input_volume_choice() {

    
    local max_input_attempts=0
    local user_input_volumes=()
    local index_specifier=$INDEX_SPECIFIER
    local host_path
    skip_volumes=false

    
    \printf "Usage: <empty> for Defaults set in the Config | 'none' to mount with no volumes | '<Volume Path:MOUNT_POINT_IN_CONTAINER>'\n"

    while (( max_input_attempts < 3 )); do

        local all_valid="true"
        \printf "\n"


        "${READ_COMMAND[@]}" "What volume/volumes do you wish to use? " "${READ_COMMAND_ARRAY_FLAG[@]}" user_input_volumes || { 
            \printf "\nError taking User Input\n"; 
            return 2; 
            }


        if [[ ${#user_input_volumes[@]} -eq 0 ]]; then

            USER_DEFINED_VOLUMES=("${VOLUMES[@]}")
            \printf "\nDefault Volumes chosen: %s\n\n" "${VOLUMES[*]}"
            return 0

        fi


        if [[ ${#user_input_volumes[@]} -eq 1 && "${user_input_volumes[$index_specifier]}" == "none" ]]; then

            skip_volumes="true"
			USER_DEFINED_VOLUMES=()
            \printf "\nNo Volumes will be mounted!\n\n"
            return 0

        fi

        # reset the array
        USER_DEFINED_VOLUMES=()

        for user_input_volume in "${user_input_volumes[@]}"; do

            if [[ "$user_input_volume" != *:* ]]; then

                \printf "\n[ERROR] %s is not in <directory>:<container mount point> format!\n" "$user_input_volume"
                all_valid="false"
                continue

            fi

            host_path="${user_input_volume%%:*}"

            if [[ -d "$host_path" ]]; then

                USER_DEFINED_VOLUMES+=("$user_input_volume")
                \printf "\n%s is good\n" "$user_input_volume"

            else

                \printf "\n[ERROR] %s is not an available Directory that can be mounted!\n" "$host_path"
                all_valid="false"
            fi

        done

        if [[ "$all_valid" == "true" ]]; then

            return 0
        
        fi

        ((max_input_attempts++))
        \printf "\nAttempt %d of 3 failed.\n\n" "$max_input_attempts"

    done


    \printf "\nMax number of failed attempts reached, exiting now!\n\n"
    return 2


}


user_input_device_choice() {


    local max_input_attempts=0
    local user_input_devices=()
    local index_specifier=$INDEX_SPECIFIER

    local host_device
    local container_device

    # This will be seen during creation
    skip_devices="false"

    \printf "Usage: <empty> for Defaults set in the Config | 'none' to not pass-through any Device | '<Device>' | '<Device:MOUNT_POINT_IN_CONTAINER>'\n"

    while (( max_input_attempts < 3 )); do

        local all_valid="true"

        \printf "\n"

        "${READ_COMMAND[@]}" \
            "What device/devices do you wish to use? " \
            "${READ_COMMAND_ARRAY_FLAG[@]}" \
            user_input_devices || {
                \printf "\nError taking User Input\n"
                return 2
            }

        if [[ ${#user_input_devices[@]} -eq 0 ]]; then

            USER_DEFINED_DEVICES=("${DEVICES[@]}")

            \printf "\nDefault Devices chosen: %s\n\n" "${DEVICES[*]}"

            return 0

        fi

        if [[ ${#user_input_devices[@]} -eq 1 \
              && "${user_input_devices[$index_specifier]}" == "none" ]]; then

            skip_devices=true
            USER_DEFINED_DEVICES=()

            \printf "\nNo Devices will be passed-through!\n\n"

            return 0

        fi

        USER_DEFINED_DEVICES=()

        for user_input_device in "${user_input_devices[@]}"; do

            host_device="$user_input_device"
            container_device=""

            if [[ "$user_input_device" == *:* ]]; then

                host_device="${user_input_device%%:*}"
                container_device="${user_input_device#*:}"

                if [[ -z "$host_device" || -z "$container_device" ]]; then

                    \printf "\n[ERROR] Invalid device format '%s'\n" "$user_input_device"

                    all_valid="false"

                    continue

                fi

            fi

            if [[ -b "$host_device" || -c "$host_device" ]]; then

                USER_DEFINED_DEVICES+=("$user_input_device")

                \printf "\n%s is good\n" "$user_input_device"

            else

                \printf "\n[ERROR] %s is not an available Device that can be passed-through!\n" "$host_device"

                all_valid="false"

            fi

        done

        if [[ "$all_valid" == "true" ]]; then

            return 0

        fi

        ((max_input_attempts++))

        \printf "\nAttempt %d of 3 failed.\n\n" "$max_input_attempts"

    done

    \printf "\nMax number of failed attempts reached, exiting now!\n\n"

    return 2

}


user_input_startup_script_choice(){



    local max_input_attempts=0
	local user_input_startup_script


    \printf "Usage: <empty> for Defaults set in the Config | <location/to/startup_script_name> for the new Startup Script!\n" 

	while ((max_input_attempts < 3)); do

       
        "${READ_COMMAND[@]}" "Enter the Startup Script you want to use: " user_input_startup_script || { 
            \printf "\nError taking User Input\n"; 
            return 2; 
            } 

        # use config default
        if [[ -z "$user_input_startup_script" ]]; then

            USER_DEFINED_STARTUP_SCRIPT="$STARTUP_SCRIPT"
            return 0

        fi


        # explicitly disable startup script
        if [[ "$user_input_startup_script" == "none" ]]; then

            USER_DEFINED_STARTUP_SCRIPT=""
            return 0

        fi


        # validate file exists
        if [[ ! -f "$user_input_startup_script" ]]; then
            
            \printf "\n[ERROR] this file does not exist!"
            ((max_input_attempts++))
            \printf "\nAttempt %d of 3 failed.\n\n" "$max_input_attempts"
            continue

        fi


        # validate file is readable
        if [[ ! -r "$user_input_startup_script" ]]; then

            \printf "\n[ERROR] this file is not readable!"
            ((max_input_attempts++))
            \printf "\nAttempt %d of 3 failed.\n\n" "$max_input_attempts"
            continue

        fi


        # validate shell script extension
        if [[ "$user_input_startup_script" != *.sh ]]; then

            \printf "\n[WARNING] This file does not end in .sh - continuing anyway...\n"

        fi


        USER_DEFINED_STARTUP_SCRIPT="$user_input_startup_script"
        return 0


    done


    \printf "\nMax number of failed attempts reached, exiting now!\n\n"
	return 2


}


print_user_input_setup(){


	clear_space
	print_line_separator
	clear_space
	\printf "User-set Choices!\n"
	\printf "%s\n\n" "------------------"
	\printf "  %-26s %s\n" "Rootful:" 					"$USER_DEFINED_ROOTFUL"
    \printf "  %-26s %s\n" "Root:" 		    			"${ROOT[*]}"
    \printf "  %-26s %s\n" "Pod:"                       "$USER_DEFINED_POD"
    \printf "  %-26s %s\n" "Pod Name:"                  "$USER_DEFINED_POD_NAME"
    \printf "  %-26s %s\n" "Pod Ports:"                 "${USER_DEFINED_POD_PORTS[*]}"
	\printf "  %-26s %s\n" "Label"                      "$USER_DEFINED_LABEL"
	\printf "  %-26s %s\n" "No. of Containers:"         "$USER_DEFINED_NO_OF_CONTAINERS"
    \printf "  %-26s %s\n" "Images:"                    "${USER_DEFINED_IMAGES[*]}"
	\printf "  %-26s %s\n" "Network:"                   "$USER_DEFINED_NETWORK"
    \printf "  %-26s %s\n" "Interactive Terminal:"      "$USER_DEFINED_INTERACTIVE_TERMINAL"
    \printf "  %-26s %s\n" "Devices:"                   "${USER_DEFINED_DEVICES[*]}"
	\printf "  %-26s %s\n" "Volumes:"                   "${USER_DEFINED_VOLUMES[*]}"
	\printf "  %-26s %s\n" "Environment Setup Script:"  "$USER_DEFINED_STARTUP_SCRIPT"
	clear_space
	print_line_separator
    clear_space
    

}


###########################################################################

############## x ##############



user_input(){

    clear_space
	print_line_separator
	clear_space

    user_input_rootful_choice || return "$?"
	clear_space
    print_line_separator
    clear_space

    user_input_pod_choice || return "$?"
    clear_space
    print_line_separator
    clear_space


    if [[ "$USER_DEFINED_POD" == "true" ]]; then    

        user_input_pod_name_choice || return "$?"
        clear_space
        print_line_separator
        clear_space

        user_input_pod_port_choice || return "$?"
        clear_space
        print_line_separator
        clear_space

        _user_pod_choice_validation_check || return "$?"

    fi

    user_input_label_choice || return "$?"
    clear_space	
	print_line_separator
	clear_space

    user_input_no_of_containers || return "$?"
    clear_space	
	print_line_separator
	clear_space

    user_input_image_choice || return "$?"
	clear_space
	print_line_separator
	clear_space


    if [[ "$USER_DEFINED_POD" == "false" ]]; then

        user_input_network_choice || return "$?"
        clear_space
        print_line_separator
        clear_space

    fi

    user_input_interactive_terminal_choice || return "$?"
	clear_space
	print_line_separator
    clear_space

    user_input_volume_choice || return "$?"
	clear_space
	print_line_separator
    clear_space

    user_input_device_choice || return "$?"
	clear_space
	print_line_separator
    clear_space

    user_input_startup_script_choice || return "$?"
	clear_space
	print_line_separator
    clear_space



}


user_input_main(){


	#Run config_validation.sh, then decide whether to continue with User Input or skip!
	. "$SCRIPTS_DIR/config_validation.sh" || return "$?"
	
    #source the global commands
    source_global_commands


    # ensure validation artifacts are always cleaned up - not sure, may remove [REVISIT]
    trap '
        prune_validation_pods >/dev/null 2>&1
        prune_validation_containers >/dev/null 2>&1
    ' EXIT INT TERM


    if [[ "$init_user_input" == "true" ]]; then		

		
        user_input || return "$?"


        # pruning just in case Trap doesnt work correctly - it may be unnecessary
        if [[ "$USER_DEFINED_POD" == "true" ]]; then

            prune_validation_pods || return "$?"

        fi

        prune_validation_containers || return "$?"


    else

        # else if no is selected then set the vars from the config 

        USER_DEFINED_LABEL="$LABEL"
        USER_DEFINED_ROOTFUL="$ROOTFUL"

        ROOT=("${ROOT[@]}")

        USER_DEFINED_POD="$POD"
        USER_DEFINED_POD_NAME="$POD_NAME"

        USER_DEFINED_POD_PORTS=("${POD_PORTS[@]}")

        USER_DEFINED_NO_OF_CONTAINERS="$NO_OF_CONTAINERS"

        USER_DEFINED_IMAGES=("${IMAGES[@]}")
        USER_DEFINED_VOLUMES=("${VOLUMES[@]}")
        USER_DEFINED_DEVICES=("${DEVICES[@]}")

        USER_DEFINED_NETWORK="$NETWORK"
        USER_DEFINED_INTERACTIVE_TERMINAL="$INTERACTIVE_TERMINAL"
        USER_DEFINED_STARTUP_SCRIPT="$STARTUP_SCRIPT"

    fi

        
    print_user_input_setup
    return 0
        
	
}



user_input_main || return "$?"