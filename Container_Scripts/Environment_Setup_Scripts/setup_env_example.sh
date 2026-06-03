#!/usr/bin/env bash

# This is a script that will run across all the test containers to create the env


# Define your packages here
PACKAGES=(
    "nano"
    "coreutils"
)

#This takes the automatically assigned $PODBOI_IMAGE (the name of the Image upon creation) and performs commands based on this
#-In this example, if the Image is a dnf/yum RHEL image, it will swap-out coreutils-single (a minimal coreutils package) for the full coreutils packages


create_logfile(){

    log_file="/app/logs/$PODBOI_NAME.log"

    if ! command -v touch &>/dev/null; then

        printf "\n[ERROR] The touch command isn't available, cannot use this command/n/n" >> "$log_file"
        return 1

    fi
    
    if [[ ! -f "$log_file" ]]; then
        \touch "$log_file"  &>/dev/null || printf "\n[ERROR] creating %s\n\n" "$log_file"

    fi

    \printf "" > "$log_file" || printf "\n[ERROR] writing to %s\n\n" "$log_file"

    export LOG_FILE="$log_file" || printf "\n[ERROR] exporting Log File variable %s\n\n" "$log_file"

    return 0

}

initialize_fkr(){

    local fkr="/app/FKR/fkr.sh"
    chmod 777 "$fkr"
    
    ln -s "$fkr" /usr/local/bin/fkr

    return 0


}

update_container(){

    #This will update the container's Repo, and upgrade any packages that need upgrading

    fkr -uu --noconfirm | tee -a "$log_file"

    return 0

}


install_packages(){

    #Install packages - read the FKR Readme (https://github.com/FMallon/FKR) for full details on flags, use etc. 
    #The [-i] flag loops individually through packages, thus allowing for failure in multi distro environment setups
    #-where package names may differ
    #If you are certain of the packages and the enviroment you are using, you can use the [-is] flag.
    #-This will ensure standard package manager behaviour
    #Alternitavely, it`s possible to take from a pre-defined file of packages, should you wish to mount or copy a file, and take package names from that. 

    fkr -i --noconfirm "${PACKAGES[@]}" | tee -a "$log_file"

    #fkr -i --noconfirm nano sudo coreutils git github | tee -a "$log_file"

    return 0

}


create_user(){


    printf "\n\n[%s] Hello, this is %s. I am %s.\n\n" "$PODBOI_IMAGE" "$PODBOI_NAME" "$(whoami)" >> "$log_file"

    if ! command -v useradd  &>/dev/null; then

        printf "\n[ERROR] Shadow-Utils may not be installed, cannot use this command/n/n" >> "$log_file"
        return 1

    fi

    \useradd -m -s /bin/bash user1 && printf "\n[SUCCESS] Creating user1 Profile\n\n" >> "$log_file" ||  {
        
        printf "\n[FAILURE] Creating user1 Profile\n\n" >> "$log_file"
        return 1
        
    }

    return 0


}

create_test_file(){

    if ! command -v touch &>/dev/null; then

        printf "\n[ERROR] The touch command isn't available, cannot use this command/n/n" >> "$log_file"
        return 1

    fi

    \touch /home/user1/test.txt && printf "\n[SUCCESS] Creating the test.txt file\n\n" >> "$log_file" || {

        printf "\n[FAILURE] Creating the test.txt file\n\n" >> "$log_file"
        return 1

    }

    return 0
 

}

display_package_manager(){


    pkgmgr="$(fkr -dpm)"

    printf "\nThe Package Manager for this Image is: %s\n\n" "$pkgmgr" >> "$log_file"


}

execute_secondary_script(){


    #Environment_Scripts directory was set to /app/Environment_Scripts in our config
    local env_scripts_dir="/app/Environment_Scripts"

    bash "$env_scripts_dir/example.sh" || printf "Error occured running the example.sh script" 

}


main(){

    create_logfile
    initialize_fkr
    update_container
    
    install_packages
    
    display_package_manager

    create_user
    create_test_file

    execute_secondary_script

}

main