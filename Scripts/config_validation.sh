#!/usr/bin/env bash


if [ -n "$BASH_VERSION" ]; then
    SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
elif [ -n "$ZSH_VERSION" ]; then
    SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
fi


CONTAINER_SCRIPTS_DIR="$SCRIPTS_DIR/../Container_Scripts"


###############################################
##Global Config Defaults

#"${DISTROS[@]}"
#$NETWORK
#$LABEL
#$NO_OF_CONTAINERS
#${VOLUMES[@]}
#${DEVICES[@]}
#$STARTUP_SCRIPT
##############################################


validate_podman_exists(){

	if ! command -v podman -v &>/dev/null; then

		\printf "\nYOU ABSOLUTE FOOL! PODMAN ISN'T EVEN INSTALLED ON THIS SYSTEM!\n\n"
		return 29

	fi

	return 0

}



verify_config_file_exists(){


#Source Config File
	if [[ -f "$CONFIG_FILE" ]]; then

		. "$CONFIG_FILE"

	else

		\printf "\n[ERROR] %s does not exist\n" "$CONFIG_FILE"
		\printf "\nYou can use --restore-default-config to restore the default Config file\n"
		\printf "\nAlternatively, you can use --config to define your own Config\n\n"

		return 15

	fi

}

############## Config Validation Section ##############


validate_config_default_mode(){

	case "$MODE" in 

		local)

			. "$SCRIPTS_DIR/set_cache_local.sh" "local"
			return 0

		;;

#		user)

#			. "$SCRIPTS_DIR/set_cache_local.sh user"
#			return 0

#		;;

#		system-wide)

#			"$SCRIPTS_DIR/set_cache_local.sh system-wide"
#			return 0

#		;;

		*)

			\printf "\n[ERROR] This is an invalid Mode\n\n"
			return 14

		;;

	esac

	return 0

}


validate_config_default_rootful(){

	#figure out Rootful & Rootless setup,
	

	case "$ROOTFUL" in


		"true")

			check_root

			return 0

		;;

		"false")

			ROOT=()

			return 0

		;;

		*)
		
			\printf "
					There is an error in the Config File!

					#########ERROR##########
					#-Rootless-#
					#--Run Containers Rootless or Rootful
					#--Usage: Boolean - must be \"true\" or \"false\"

					'ROOTFUL' must be a boolean value (true/false)!

				"
				
				#reset the buffer, else the terminal shifts far to the right
				clear_space

				return 3
		;;

	esac 



}

validate_config_default_pod(){


	#[TAKE ANOTHER LOOK AT THIS]
	#- cmd could be initialialized before building everything, but i think it's fine - plus i dont like the name cmd, so change


	local pod_name="$POD_NAME"
	local pod="$POD"
	local pod_ports=("${POD_PORTS[@]}")
	local pod_port_args=()



	if [[ "$pod" != "true" && "$pod" != "false" ]]; then

		\printf "
			There is an error in the Config File!

			#########ERROR##########
			#-Pod-#
			#--Set up a Pod upon Container Creation
			#--Usage Example: POD=true or POD=false

			POD must be a boolean value (true/false)!

			"
				
		#reset the buffer, else the terminal shifts far to the right
		clear_space
		return 3

	fi


	if [[ "$pod" != "true" ]]; then

		return 0

	fi


	if [[ -z "$pod_name" ]]; then

		\printf "
			There is an error in the Config File!

			#########ERROR##########
			#-Pod Name-#
			#--Set up a Pod upon Container Creation
			#--Usage Example: POD_NAME=\"Backend\"

			You can't use an empty name for a Pod!
			
			"
				
		#reset the buffer, else the terminal shifts far to the right
		clear_space

		return 3

	fi


	# validate pod name characters
	if [[ ! "$pod_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then

		\printf "
			There is an error in the Config File!

			#########ERROR##########
			#-Pod Name-#
			#--Set up a Pod upon Container Creation
			#--Usage Example: POD_NAME=\"Backend\"

			'%s' contains invalid characters!

			Valid = ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$

			" "$pod_name"

		clear_space
		return 3

	fi


	# if pod exists, then warn, display info
	if "${ROOT[@]}" podman pod exists "$pod_name" &>/dev/null; then

		local _pod_info
		_pod_info="$("${ROOT[@]}" podman pod inspect "$pod_name" 2>/dev/null | head -n 13 | tail -n 11)"

		\printf "\n
			[WARNING] The Pod %s exists and will thus be used.  If you do not wish to use this Pod, you should cancel with [ctrl + c]\n
			If SKIP_RUNTIME_CHANGES is set to false, you can change during the Runtime Changes section\n
			Below will be information about the selected Pod's Ports so you may avoid clashes\n
			" "$pod_name"

		clear_space
		\printf "%s" "$_pod_info"
		clear_space

		sleep 7

		POD_PORTS=()
		return 0 

	fi


	for pod_port in "${pod_ports[@]}"; do

		if [[ -z "$pod_port" ]]; then
			
			continue
		
		fi


		# validate HOST:CONTAINER format
		if [[ ! "$pod_port" =~ ^[0-9]+:[0-9]+$ ]]; then

			\printf "
				There is an error in the Config File!

				#########ERROR##########
				#-Pod Ports-#
				#--Usage Example: POD_PORTS=(\"8080:80\" \"8443:443\")

				'%s' is not in a valid HOST:CONTAINER format!

			" "$pod_port"

			clear_space
			return 3

		fi


		local host_port="${pod_port%%:*}"
		local container_port="${pod_port##*:}"


		# validate port ranges
		if (( host_port < 1 || host_port > 65535 )); then

			\printf "
				There is an error in the Config File!

				#########ERROR##########
				#-Pod Ports-#

				'%s' is not a valid host port!

			" "$host_port"

			clear_space
			return 3

		fi


		if (( container_port < 1 || container_port > 65535 )); then

			\printf "
				There is an error in the Config File!

				#########ERROR##########
				#-Pod Ports-#

				'%s' is not a valid container port!

			" "$container_port"

			clear_space
			return 3

		fi


		# prevent duplicate host ports
		for existing_port in "${pod_port_args[@]}"; do

			if [[ "$existing_port" == "$host_port" ]]; then

				\printf "
					There is an error in the Config File!

					#########ERROR##########
					#-Pod Ports-#

					Duplicate host port detected: '%s'

				" "$host_port"

				clear_space
				return 3

			fi

		done


		pod_port_args+=("$host_port")

		# if lsof doesn't exist, allow to pass, and this should hopefully be caught during creation time
		# - allows less dependencies, and user's without lsof will be able to continue
		if ! command -V lsof &> /dev/null; then

			return 0

		fi

		# check if host port is already bound - lsof is actually probably best, makes me seem more professional; i think every system has it.
		if lsof -i :"$host_port" &>/dev/null; then

			\printf "
				There is an error in the Config File!

				#########ERROR##########
				#-Pod Ports-#

				Host Port '%s' is already in use!

			" "$host_port"

			clear_space
			return 3

		fi

	done


	clear_space
	return 0


}



validate_config_default_label(){


	local label="$LABEL"
	local _get_containers_by_label=("${GET_CONTAINERS_BY_LABEL[@]}")
	local _get_current_env=$(get_current_env)

	_get_containers_by_label+=("--filter" "label=$label")

	if [[ -z "$LABEL" ]]; then

		\printf "
			There is an error in the Config File!

			#########ERROR##########
			#-Label-#
			#--Set-up a unifying Label Name for the current environment instance being created
			#--Usage Example: LABEL=\"dev\"
					

			'LABEL' can not be empty!

			"
			
		clear_space
		return 3

	fi

	if [[ ! "$LABEL" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then

		\printf "
			There is an error in the Config File!

			#########ERROR##########
			#-Label-#
			#--Set-up a unifying Label Name for the current environment instance being created
			#--Usage Example: LABEL=\"dev\"
					

			'LABEL' can not contain a space nor certain characters!

			Valid = ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$

			"
			
		clear_space
		return 3

	fi


	local check_label_exists=$("${_get_containers_by_label[@]}" | wc -l) 

	if (( check_label_exists > 0 )); then

		\printf "
			There is an error in the Config File!

			#########ERROR##########
			#-Label-#
			#--Set-up a unifying Label Name for the current environment instance being created
			#--Usage Example: LABEL=\"dev\"
					

			The specified label '%s' already exists!

			" "$label"
			
		
		#reset the buffer, else the terminal shifts far to the right
		clear_space
		return 3


	fi

	return 0


}


validate_config_default_no_of_containers(){


	if [[ ! "$NO_OF_CONTAINERS" =~ ^[1-9][0-9]*$ ]]; then

		\printf "
			There is an error in the Config File!

			#########ERROR##########
			#-Number of Containers-#
			#--The number of containers to create - warning: must be 1 or more
			#--Usage Example: NO_OF_CONTAINERS=1

		"

		#reset the buffer, else the terminal shifts far to the right
		clear_space
	
		return 3

	fi

	return 0



}


validate_config_default_images(){



	if (( ${#IMAGES[@]} == 0 )); then 

		\printf "
			There is an error in the Config File!

			#########ERROR##########
			#-Images-#
			#--The absolute Default in the case where no Images are inputted by the User will be the first entry in the array!
			#--Usage Example: IMAGES=(\"<Image_Name_1>\" \"<Image_Name_2>\" \"<Image_Name_3>\")

			There must be at least 1 Image in the Config file!

		"

		#reset the buffer, else the terminal shifts far to the right
		clear_space

		return 3


	fi


        for image in "${IMAGES[@]}"; do

		if ! "${ROOT[@]}" podman image inspect "$image" &>/dev/null && ! "${ROOT[@]}" podman manifest inspect "$image" &>/dev/null; then

		\printf "
			There is an error in the Config File!

			#########ERROR##########aa
			#-Image-#
			#--The absolute Default in the case where no Images are inputted by the User will be the first entry in the array!
			#--Usage Example: IMAGES=(\"<Image_Name_1>\" \"<Image_Name_2>\" \"<Image_Name_3>\")

			'%s' is not a valid Distribution!

			If it is a valid Distribution, you could have a network issue, or there could be possible issues with the Docker (or wherever Podman pulls their images from) mirrors at the moment, or be Rate-limited by docker.
			You can add extra registry to your /etc/containers/registries.conf file to mitigate this.

			In the case where you are trying to use an Image, make sure the Rootless state of your stored image matches the Rootless state of your current PodBOI Environment!
			By default, Podman stores these in seperate locations.

			Try running \"podman manifest inspect %s\" or \"podman manifest inspect %s\" to get a more definitive answer to your issue. 

		" "$image" "$image" "$image"

			#reset the buffer, else the terminal shifts far to the right
			clear_space

			return 3

		fi

	done

	return 0


}


validate_config_default_volumes(){


	if [[ -z "${VOLUMES[@]}" ]]; then

		return 0

	fi

	for volume in "${VOLUMES[@]}"; do

		volume="${volume%%:*}"

		if [[ ! -d "$volume" ]]; then

			\printf "
				There is an error in the Config File!

				#########ERROR##########
				#-Volume-#
				#--Volumes to be mounted on startup!
				#--Alternitavely, if using Selinux, add :z or :Z to the end!
				#--Usage Example: VOLUMES=(\"<Directory_Name_1>:<VOLUME_MOUNT_PATH_INSIDE_CONTAINER_1>\" \"<Directory_Name_2>:<VOLUME_MOUNT_PATH_INSIDE_CONTAINER_2>\"

				'$volume' is not a valid Directory!

			"
			
			#reset the buffer, else the terminal shifts far to the right
			clear_space

			return 3

		fi

	done
	
	return 0

}



validate_config_default_devices(){


	if [[ -z "${DEVICES[@]}" ]]; then 

		return 0

	fi

	for device in "${DEVICES[@]}"; do

		device="${device%%:*}"

		if [[ ! -e "$device" ]]; then
			
			\printf "
				There is an error in the Config File!

				#########ERROR##########
				#-Device-#
				#--Devices to be passed-through to the Container! Can be commented out!
				#--Usage Example: DEVICES=(\"<HOST_DEVICE_Name1>:<CONTAINER_DEVICE_Name1>:<Permissions>\" \"<HOST_DEVICE_Name2>:<CONTAINER_DEVICE_Name2>:<Permissions>\")

				'$device' does not exist!

			"

			clear_space

			return 3

		fi

		if [[ ! -b "$device" && ! -c "$device" ]]; then

			\printf "
				There is an error in the Config File!

				#########ERROR##########
				#-Device-#
				#--Devices to be passed-through to the Container! Can be commented out!
				#--Usage Example: DEVICES=(\"<HOST_DEVICE_Name1>:<CONTAINER_DEVICE_Name1>:<Permissions>\" \"<HOST_DEVICE_Name2>:<CONTAINER_DEVICE_Name2>:<Permissions>\")

				[NOTE] It could be a Device Passthrough issue in VM/MacOS - maybe something about Rootless or some shit.... think about this one after testing on Hardware

				'$device' is not a valid Block or Character Device!

			"

			clear_space
			return 3


		fi

	done


	return 0


}

validate_config_default_interactive_terminal(){



	case "$INTERACTIVE_TERMINAL" in

		true)

			INTERACTIVE_TERMINAL="true"
			return 0

		;;

		false)

			INTERACTIVE_TERMINAL="false"
			return 0

		;;

		*)

			\printf "There is an error in the Config File!


			#-Interactive Terminal-#
			#--Whether or not the Interactive Terminal will be used during creation
			#--Usage Example: INTERACTIVE_TERMINAL=\"true\" || INTERACTIVE_TERMINAL=\"false\"

			INTERACTIVE_TERMINAL must be a boolean value (true/false)!
			"			
			
			return 3

		;;

	esac

}


validate_config_default_network(){


	#[TEST]
	# if pod is true, there is no need to test for this, the question is,
	# - do i do pod == true, and skip_runtime_changes == true
	# -- because if not valid, i dont want it to skip by mistake, if i remember correctly, it will assume it's valid already from the config, needs to be verified; 
	if [[ "$POD" == "true" && "$SKIP_RUNTIME_CHANGES" == "true" ]]; then

		return 0

	fi

	
	if [[ -z "$NETWORK" ]]; then 

		NETWORK="none"
		return 0

	fi


	# Don't rely on podman network exists - it's fkn shite and keeps erroring out!
	if ! "${ROOT[@]}" podman network inspect "$NETWORK" &>/dev/null; then

		\printf "
			There is an error in the Config File!

			#########ERROR##########
			#-Network-#
			#--Networks to be used with the containers! Can be commented out, and will default to \"none\"!
			#--Usage Example: NETWORK=\"podman\" NETWORK=\"none\" NETWORK=\"cni\" #NETWORK=\"slirp4netns\"

			'%s' is not a valid network!

		" "$NETWORK"

		#reset the buffer, else the terminal shifts far to the right
		clear_space
		
		return 3

	fi


	return 0


}

validate_config_default_startup_script(){


	
	if [[ -z "$STARTUP_SCRIPT" ]]; then

		return 0

	fi


	if [[ ! -f "$STARTUP_SCRIPT" ]]; then

		\printf "
			There is an error in the Config File!

			#########ERROR##########
			#-Startup Script-#
			#--Startup Script to be ran for Environment Setup! Can be commented out!
			#--Usage Example: STARTUP_SCRIPT=\"/PATH/TO/SCRIPT/script_name.sh\"

			'%s' is not a valid File!

			" "$STARTUP_SCRIPT"
			
		#reset the buffer, else the terminal shifts far to the right
		clear_space

		return 3

	fi


	if [[ ! -r "$STARTUP_SCRIPT" ]]; then

		\printf "
			There is an error in the Config File!

			#########ERROR##########
			#-Startup Script-#
			#--Startup Script to be ran for Environment Setup! Can be commented out!
			#--Usage Example: STARTUP_SCRIPT=\"/PATH/TO/SCRIPT/script_name.sh\"

			'%s' is not readable!

			" "$STARTUP_SCRIPT"

		clear_space
		return 3

	fi


	# this could be an issue not sure though
	if [[ "$STARTUP_SCRIPT" != *.sh ]]; then

		\printf "
			[WARNING]

			The Startup Script does not end in '.sh'

			Continuing anyway...

			"

		clear_space

	fi


	return 0

}

prune_validation_containers(){



    # make sure to prune the containers that are made for validation purposes!

    # find podman label --PodBOI_Validation, then rm them

    local _get_containers_by_label_validation=()
	_get_containers_by_label_validation+=("${ROOT[@]}")
	_get_containers_by_label_validation+=("${GET_CONTAINERS_BY_LABEL_VALIDATION[@]}")

    local existing_containers_validation=$("${_get_containers_by_label_validation[@]}")


    if [[ -z "$existing_containers_validation" ]]; then

        return 0

    fi

    while IFS= read -r container_name; do 

        "${ROOT[@]}" "${REMOVE_CONTAINER[@]}" "$container_name" &>/dev/null || { 
            \printf "\n[ERROR] has occured during Validation Container Pruning\n\n"; 
            return 4; 
            }

    done <<< "$existing_containers_validation"

    return 0   

    clear_space



}

prune_validation_pods(){


    local _get_pods_by_label_validation=()

	_get_pods_by_label_validation+=("${ROOT[@]}")
	_get_pods_by_label_validation+=("${GET_PODS_BY_LABEL_VALIDATION[@]}")

    local existing_pods_validation=$("${_get_pods_by_label_validation[@]}")


    if [[ -z "$existing_pods_validation" ]]; then

        return 0

    fi

    while IFS= read -r pod_name; do 

        "${ROOT[@]}" "${REMOVE_POD[@]}" "$pod_name" &>/dev/null || { 
            \printf "\n[ERROR] has occured during Validation Pod Pruning\n\n"; 
            return 4; 
            }

    done <<< "$existing_pods_validation"

	clear_space

    return 0   

    


}



print_config_setup(){



#-Distros & Number of Containers must be more than one, and Network will default to none, so no need to account for them! 

local pod_ports="${POD_PORTS[*]}"
local image_list="${IMAGES[*]}"
local volume_list="${VOLUMES[*]}"
local device_list="${DEVICES[*]}"


if [[ -z "$startup_script" ]]; then

	startup_script="None"

fi


if [[ -z "$volume_list" ]]; then

	volume_list="None"

fi


if [[ -z "$device_list" ]]; then

	device_list="None"

fi


if [[ -z "$POD_NAME" ]]; then

	pod_name="None"

fi


if [[ -z "${POD_PORTS[@]}" ]]; then

	pod_ports="None"

fi

	clear_space
	print_line_separator
	clear_space
	
	\printf "Set Config Defaults\n"
	\printf "%s\n" "--------------------"
	
	\printf "  %-26s %s\n" "Rootful:" 					"$ROOTFUL"

	\printf "  %-26s %s\n" "Pod:" 						"$POD"
	\printf "  %-26s %s\n" "Pod Name:" 					"$POD_NAME"
	\printf "  %-26s %s\n" "Pod Ports:" 				"$pod_ports"

	\printf "  %-26s %s\n" "Label:" 					"$LABEL"
	
	\printf "  %-26s %s\n" "No. of Containers:"         "$NO_OF_CONTAINERS"
	\printf "  %-26s %s\n" "Images:"                    "$image_list"
	\printf "  %-26s %s\n" "Network:"                   "$NETWORK"
	\printf "  %-26s %s\n" "Volumes:"                   "$volume_list"
	\printf "  %-26s %s\n" "Devices:"                   "$device_list"
	
	\printf "  %-26s %s\n" "Environment Setup Script:"  "$STARTUP_SCRIPT"
	clear_space
	print_line_separator


}




validate_setup_change(){

    local max_input_attempts=0
	local input
	init_user_input=false

	while ((max_input_attempts < 3)); do

		${READ_COMMAND[@]} "Do you wish to make changes to your setup [y/n]? " input || { 
			\printf "Error taking User Input!"; 
			return 2; 
			}

		case "$input" in

			[Yy] | [Yy][Aa][Hh] | [Yy][Ee][Ss])

				init_user_input=true
				return 0

			;;

			[Nn] | [Nn][Oo][Pp][Ee] | [Nn][Aa][Hh] | [Nn][Oo])

				init_user_input=false
				return 0

			;;

			*)

				\printf "\n[ERROR] This is invalid, please enter y/n!\n"
				((max_input_attempts++))
		        \printf "\nAttempt %d of 3 failed.\n" "$max_input_attempts"


			;;

		esac


	done	

	
	\printf "Max number of failed attempts reached, exiting now!\n\n"
	return 2



}



validate_config(){

	
	
	clear_space
	\printf "Validating Config entries....\n"

	#This is necessary because other MODES are not supported - tbh they dont need to be
	MODE="local"

	validate_config_default_mode || return "$?"
	validate_config_default_rootful || return "$?"
	validate_config_default_pod || return "$?"
	validate_config_default_label || return "$?"
	validate_config_default_interactive_terminal || return "$?"
	validate_config_default_no_of_containers || return "$?"
	validate_config_default_images || return "$?"
	validate_config_default_network || return "$?"
	validate_config_default_volumes || return "$?"
	validate_config_default_devices || return "$?"
	validate_config_default_startup_script || return "$?"


	print_config_setup

	if [[ "$SKIP_RUNTIME_CHANGES" != "true" ]]; then
	
		clear_space
		validate_setup_change || return "$?"

		return 0

	fi

    USER_DEFINED_ROOTFUL="$ROOTFUL"
    ROOT=("${ROOT[@]}")
    USER_DEFINED_POD="$POD"
    USER_DEFINED_POD_NAME="$POD_NAME"
    USER_DEFINED_POD_PORTS="${POD_PORTS[@]}"
    USER_DEFINED_LABEL="$LABEL"
    USER_DEFINED_NO_OF_CONTAINERS=$NO_OF_CONTAINERS
    USER_DEFINED_IMAGES=("${IMAGES[@]}")
    USER_DEFINED_VOLUMES=("${VOLUMES[@]}")
    USER_DEFINED_DEVICES=("${DEVICES[@]}")
	USER_DEFINED_INTERACTIVE_TERMINAL="$INTERACTIVE_TERMINAL"
    USER_DEFINED_NETWORK="$NETWORK"
    USER_DEFINED_STARTUP_SCRIPT="$STARTUP_SCRIPT"

	return 0


}




validate_config_main(){

	
	validate_podman_exists || return "$?"

	verify_config_file_exists || return "$?"

	validate_config || return "$?"


}


validate_config_main || return "$?"