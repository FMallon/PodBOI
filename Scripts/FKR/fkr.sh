#!/usr/bin/env bash

############################ Finzell's Unified Linux Kernel Package Management Resolver ############################
#-Or 'fkr' for short.... how it's pronounced is up to the imagination!
#-A way to standardize and make managing packages across multple distros easier
#-Will begin with Pacman, Apt, dnf, apk, brew & Zypper cuz I need them for Containers and my MacOS
#-More can, and maybe will be, added in the future, like Unix Package Managers - I can't think of any more except for NixOS... but that's done through a Config file - will see in the future  
#-I will not be doing this for Portage - that's its own thing, and using Emerge makes more sense, especially as it pertains to necessary output regarding USE Flags and Masks etc.

#### Returns ####
# 
#-Return 2: Error: Unsupported Package Manager
#-Return 3: Error: Invalid Super User privileges
#-Return 4: Error: No Packages Specified
#-Return 5: Error finding input file
#-Return 6: Error writing to temporary log
#-Return 7: Error cleaning temporary logs from memory
#-Return 8: Error: Invalid Flag
#-Return 9: Error: Updating the Repository 



if [ -n "$BASH_VERSION" ]; then
    MAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
elif [ -n "$ZSH_VERSION" ]; then
    MAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
fi


PKGMNGR=()
ROOT=()

INSTALL_PKG=() 
REMOVE_PKG=()
QUERY_PKG=()
QUERY_REPO=()
UPDATE=()
UPGRADE=()

DRYRUN_FLAG=()
NO_CONFIRM_FLAG=()



check_root(){


    local root=()

    #check for current privilege status
    if [[ "$EUID" -eq 0 ]]; then 

        ROOT=()
        return 0

    fi

    #test for sudo or doas
    if command -v sudo >/dev/null 2>&1; then
        
        root=(sudo)
        ROOT=("${root[@]}")

    elif command -v doas >/dev/null 2>&1; then

        root=(doas)
        ROOT=("${root[@]}")

    else

        \printf "\n\n[ERROR] You need root privilege to run this - Sudo nor Doas appear to be installed!\n\n"
        return 3

    fi 
    
    
    return 0


}




get_pkgmgr(){


    if command -v apt-get >/dev/null 2>&1; then 

        PKGMNGR=("apt-get")
        INSTALL_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" "install")
        REMOVE_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" "remove")
        QUERY_PKG=("dpkg" "-s")
        QUERY_REPO=("apt-cache" "show")

        UPDATE=("${ROOT[@]}" "${PKGMNGR[@]}" "update")
        UPGRADE=("${ROOT[@]}" "${PKGMNGR[@]}" "upgrade")

        NO_CONFIRM_FLAG=("-y")
        DRYRUN_FLAG=("-s")
        
        return 0


    elif command -v dnf >/dev/null 2>&1; then 

        PKGMNGR=("dnf")
        INSTALL_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" "install")
        REMOVE_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" "remove")
        QUERY_PKG=("${PKGMNGR[@]}" "list" "installed")
        QUERY_REPO=("${PKGMNGR[@]}" "info")

        UPDATE=("${ROOT[@]}" "${PKGMNGR[@]}" "check-update")
        UPGRADE=("${ROOT[@]}" "${PKGMNGR[@]}" "upgrade")

        NO_CONFIRM_FLAG=("-y")
        DRYRUN_FLAG=("--assumeno")

        return 0

#Testing
    elif command -v yum >/dev/null 2>&1; then 

        PKGMNGR=("yum")
        INSTALL_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" "install")
        REMOVE_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" "remove")
        QUERY_PKG=("${PKGMNGR[@]}" "list" "installed")
        QUERY_REPO=("${PKGMNGR[@]}" "info")

        UPDATE=("${ROOT[@]}" "${PKGMNGR[@]}" "check-update")
        UPGRADE=("${ROOT[@]}" "${PKGMNGR[@]}" "upgrade")

        NO_CONFIRM_FLAG=("-y")
        DRYRUN_FLAG=("--assumeno")

        return 0

    elif command -v pacman >/dev/null 2>&1; then 

        PKGMNGR=("pacman")
        INSTALL_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" "-S")
        REMOVE_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" "-R")
        QUERY_PKG=("${PKGMNGR[@]}" "-Q")
        QUERY_REPO=("${PKGMNGR[@]}" "-Si")

        UPDATE=("${ROOT[@]}" "${PKGMNGR[@]}" "-Sy")
        UPGRADE=("${ROOT[@]}" "${PKGMNGR[@]}" "-Syu")

        NO_CONFIRM_FLAG=("--noconfirm")
        DRYRUN_FLAG=("--print")

        return 0



    elif command -v zypper >/dev/null 2>&1; then

        PKGMNGR=("zypper")

        INSTALL_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" "install" "-y")
        REMOVE_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" "remove" "-y")
        QUERY_PKG=("${PKGMNGR[@]}" "search" "--installed-only")
        QUERY_REPO=("${PKGMNGR[@]}" "info")

        UPDATE=("${ROOT[@]}" "${PKGMNGR[@]}" "refresh")
        UPGRADE=("${ROOT[@]}" "${PKGMNGR[@]}" "update")

        NO_CONFIRM_FLAG=("-y")
        DRYRUN_FLAG=("--dry-run")

        return 0

   
    elif command -v brew >/dev/null 2>&1; then

    #Check if brew needs Root, because I don't recall ever using sudo with brew ever!
    #And I think it's --cask for CLI Tools specifically, which is all I care about!

        PKGMNGR=("brew")

        INSTALL_PKG=("${PKGMNGR[@]}" "install")
        REMOVE_PKG=("${PKGMNGR[@]}" "uninstall")
        QUERY_PKG=("${PKGMNGR[@]}" "list")
        QUERY_REPO=("${PKGMNGR[@]}" "info")

        UPDATE=("${PKGMNGR[@]}" "update")
        UPGRADE=("${PKGMNGR[@]}" "upgrade")

        NO_CONFIRM_FLAG=()
        DRYRUN_FLAG=("--dry-run")

        return 0

    
    elif command -v apk >/dev/null 2>&1; then 

        PKGMNGR=("apk")

        INSTALL_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" "add")
        REMOVE_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" "del")
        QUERY_PKG=("${PKGMNGR[@]}" "info" "-e")
        QUERY_REPO=("${PKGMNGR[@]}" "info")

        UPDATE=("${ROOT[@]}" "${PKGMNGR[@]}" "update")
        UPGRADE=("${ROOT[@]}" "${PKGMNGR[@]}" "upgrade")

        NO_CONFIRM_FLAG=()
        DRYRUN_FLAG=("--simulate")

        return 0

    ###Template for adding another Package Manager###
    #-Keep in mind that some package managers don't require root to run certain commands, so adjust as necessary
    #elif command -v #package-manager >/dev/null 2>&1; then 

        #PKGMNGR=(package-manager)

        #INSTALL_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" package-manager-install_package-command)
        #REMOVE_PKG=("${ROOT[@]}" "${PKGMNGR[@]}" package-manager-remove_package-command)
        #QUERY_PKG=("${PKGMNGR[@]}" package-manager-query-installed_package-command)
        #QUERY_REPO=("${PKGMNGR[@]}" package-manager-query-repo_package-command)

        #UPDATE=("${ROOT[@]}" "${PKGMNGR[@]}" package-manager-update_package-command)
        #UPGRADE=("${ROOT[@]}" "${PKGMNGR[@]}" package-manager-upgrade_package-command)

        #DRYRUN_FLAG=(package-manager-dry-run_package-command)
        #NO_CONFIRM_FLAG=(package-manager-no-confirm-package-command)
 

        #return 0

    else 

        \printf "\nError, this is an unsupported Package Manager!\n\n"
        return 2 
    
    fi


}



display_package_manager(){



    #make this more portable for user`s so they can include it in other scripts so they don't have to write their own pkgmngr detection
    #not sourced so can't export var, and making them use eval would be a pain in the fkn ass

    #So User can, in their own scripts, now use - 
    # "pkgmngr=$(fkr -dpm)"
    # if [[ $pkgmngr == "pacman" ]]; then 
    #   do whatever
    # fi
    #
    #If return status is 2, then the package manager is unsupported, so best test for that first!
    

    get_pkgmgr || return "$?"

        \printf "%s\n" "${PKGMNGR[@]}"
        return 0


}



clear_space(){


    \printf "\n\n"


}




print_line_separator(){


    \printf "\n__________________________________________________________________________________________\n"


}




set_space(){

    clear_space
    print_line_separator
    clear_space

}




cleanup(){

   
    
    \rm -f "$log_success" "$log_failure"


}




print_temp_file(){

  #Forego Cat just in case it doesn't exist - like in a very minimal container;


    for log_file in "$log_success" "$log_failure"; do

        while IFS= read -r line; do

            \printf "%s\n" "$line"

        done < "$log_file"

    done


}




open_temp_file(){


    log_success=$(mktemp) || return 6
    log_failure=$(mktemp) || return 6


}




validate_environment(){


    get_pkgmgr || return "$?"
    
    return 0    


}




read_pkg_from_file(){


    local pkg=""
    pkgs=()

    if [[ ! -f "$user_defined_pkg_file" ]]; then 

        \printf "\n[ERROR] cannot find file '%s'!\n\n" "$user_defined_pkg_file"
        return 5

    fi

    while IFS= read -r pkg; do

        if [[ "$pkg" =~ ^# ]]; then

            continue

        fi
        
        if [[ -z "$pkg" ]]; then
        
            continue

        fi

        pkg="${pkg#"${pkg%%[![:space:]]*}"}"
        pkg="${pkg%"${pkg##*[![:space:]]}"}"
        pkgs+=("$pkg")


    
    done < "$user_defined_pkg_file"
    

    return 0


}





parse_flags_min(){



    dry_run_check=0
    no_confirm_check=0

    while (($# > 0)); do 

        case "$1" in 

            --dry-run)
            dry_run_check=1
            shift
            ;;

        --noconfirm | -y)
            no_confirm_check=1
            shift
            ;;

        --)
            shift 
            break
        ;;

        *)
            printf "\n[ERROR] this is an invalid flag!\n"
            usage
            return 8
        ;;
            
        esac
        
    done

    return 0

}





 parse_flags_full(){



    user_defined_pkg_file=""
    dry_run_check=0
    no_confirm_check=0
    pkgs=()
    pkg_overflow_check=0

   

    while (($# > 0)); do
    
        case "$1" in 

            --from-file)
                if [[ -z "$2" || "$2" == -* ]]; then
                    \printf "\n[ERROR] '--from-file' requires a valid file path\n\n"
                    return 8
                fi

                #Stops a combining of pkg input plus from file input
                if [[ "${#pkgs[@]}" -gt 0 ]]; then
                    \printf "\n[ERROR] Cannot combine '--from-file' with direct package arguments\n\n"

                    return 8
                fi

                user_defined_pkg_file="$2"
                shift 2
                read_pkg_from_file || return "$?"

                pkg_overflow_check=1

            ;;

            --dry-run)
                #Do a dry run
                dry_run_check=1
                shift
            ;;

            --noconfirm | -y)
                #Add no confirm flag
                no_confirm_check=1
                shift
            ;;

            --)
                #End of flags
                shift
                break 
            ;;

            -*)
                #Invalid flag - usage()
                \printf "\n[ERROR] This is an invalid flag\n\n"
                usage
                return 8 
            ;;

            *) 

                if [[ "$pkg_overflow_check" -eq 1 ]]; then
                    
                    \printf "\n[ERROR] Cannot combine '--from-file' with direct package arguments\n\n"
                    return 8

                fi
                
                #packages
                pkgs+=("$1")
                shift
            ;;

        esac


    done



    return 0


}




verify_no_of_pkgs(){


  
    if [[ "${#pkgs[@]}" -eq 0 ]]; then

      \printf "[ERROR] No Packages have been specified!"
      return 4

    fi

    return 0


}




query_pkg(){

   

    validate_environment || return "$?"
    open_temp_file || return "$?"
    parse_flags_full "$@" || return "$?"

    verify_no_of_pkgs || return "$?"

    local query_pkg=("${QUERY_PKG[@]}")


    
    if [[ "$dry_run_check" -eq 1 ]]; then
      
      query_pkg+=("${DRYRUN_FLAG[@]}")

    fi



    if [[  "$no_confirm_check" -eq 1 ]]; then

      query_pkg+=("${NO_CONFIRM_FLAG[@]}")

    fi



    for pkg in "${pkgs[@]}"; do

      "${query_pkg[@]}" "$pkg"
      local status="$?"

      if [[ "$status" -eq 0 ]]; then
          
        \printf "Package '%s' exists\n" "$pkg" >> "$log_success" \
      
      else
        
        \printf "Package '%s' not found\n" "$pkg" >> "$log_failure"

      fi
    
    done


    set_space
    print_temp_file
    set_space
    cleanup

    return 0

}




query_repo(){




    validate_environment || return "$?"
    open_temp_file || return "$?"
    parse_flags_full "$@" || return "$?"

    verify_no_of_pkgs || return "$?"

    local query_repo=("${QUERY_REPO[@]}")


    if [[ "$dry_run_check" -eq 1 ]]; then 
    
        query_repo+=("${DRYRUN_FLAG[@]}")

    fi


    if [[ "$no_confirm_check" -eq 1 ]]; then

        query_repo+=("${NO_CONFIRM_FLAG[@]}")

    fi


    for pkg in "${pkgs[@]}"; do

        "${query_repo[@]}" "$pkg"

        local status="$?"
        
        if [[ "$status" -eq 0 ]]; then
            
        \printf "Package '%s' exists in the %s Repo\n" "$pkg" "${PKGMNGR[@]}" >> "$log_success" \
        
        else
        
        \printf "Package '%s' not found in the %s Repo\n" "$pkg" "${PKGMNGR[@]}" >> "$log_failure"

        fi
        
    done


        set_space
        print_temp_file || return "$?"
        set_space
        cleanup
    

}


install_packages_standard(){



    check_root || return "$?"

    validate_environment || return "$?"
    parse_flags_full "$@" || return "$?"

    verify_no_of_pkgs || return "$?"

    local install_pkg=("${INSTALL_PKG[@]}")


    
    if [[ "$dry_run_check" -eq 1 ]]; then

        install_pkg+=("${DRYRUN_FLAG[@]}")

    fi 

    
    if [[ "$no_confirm_check" -eq 1 ]]; then

        install_pkg+=("${NO_CONFIRM_FLAG[@]}")

    fi

    
    "${install_pkg[@]}" "${pkgs[@]}"


}



install_packages(){



    check_root || return "$?"

    validate_environment || return "$?"
    open_temp_file || return "$?"
    parse_flags_full "$@" || return "$?"

    verify_no_of_pkgs || return "$?"

    local install_pkg=("${INSTALL_PKG[@]}")
         

    
    if [[ "$dry_run_check" -eq 1 ]]; then

        install_pkg+=("${DRYRUN_FLAG[@]}")

    fi


    if [[ "$no_confirm_check" -eq 1 ]]; then

         install_pkg+=("${NO_CONFIRM_FLAG[@]}")

    fi


    for pkg in "${pkgs[@]}"; do



       "${install_pkg[@]}" "$pkg"
       local status="$?"

        if [[ $status -eq 0 ]]; then
         
            \printf "[SUCCESS] Package '%s' has been installed\n" "$pkg" >> "$log_success"
        
        else

            \printf "[ERROR] Package '%s' has not been installed\n" "$pkg" >> "$log_failure"

        fi
            
    done

    


    set_space
    print_temp_file || return "$?"
    set_space
    cleanup

    return 0


}



update_repo(){



    check_root || return "$?"

    validate_environment || return "$?"

    #if dry-run is true, dry-run flag; if no-confirm flag is true, no-confirm; if both are true, then do both - figure a more efficient way to do this!

    local update=("${UPDATE[@]}")


    "${update[@]}"
    local status="$?"
    if [[ "$status" -ne 0 ]]; then

      \printf "\n[ERROR] there was an issue updating the Repository!\n\n"
      return 9

    fi

    return 0


}



upgrade_packages(){


    check_root || return "$?"

    validate_environment || return "$?"
    parse_flags_min "$@" || return "$?"


    local upgrade=("${UPGRADE[@]}")

    if [[ "$dry_run_check" -eq 1 ]]; then

      upgrade+=("${DRYRUN_FLAG[@]}")

    fi


    if [[ "$no_confirm_check" -eq 1 ]]; then

      upgrade+=("${NO_CONFIRM_FLAG[@]}")

    fi


    "${upgrade[@]}" 
    local status="$?"

    if [[ "$status" -ne 0 ]]; then

      \printf "\n[ERROR] There was an error during the upgrade process!\n\n"
      return 10

    fi

    return 0


}


remove_packages_standard(){



    check_root || return "$?"

    validate_environment || return "$?"
    parse_flags_full "$@" || return "$?"

    verify_no_of_pkgs || return "$?"

    local remove_pkg=("${REMOVE_PKG[@]}")


    if [[  "$dry_run_check" -eq 1 ]]; then
    
        remove_pkg+=("${DRYRUN_FLAG[@]}")

    fi

    
    if [[ "$no_confirm_check" -eq 1 ]]; then

        remove_pkg+=("${NO_CONFIRM_FLAG[@]}")

    fi


    "${remove_pkg[@]}" "${pkgs[@]}"

  

}



remove_packages(){


    
    
    check_root || return "$?"

    validate_environment || return "$?"
    open_temp_file || return "$?"
    parse_flags_full "$@" || return "$?"

    verify_no_of_pkgs || return "$?"

    local remove_pkg=("${REMOVE_PKG[@]}")
         

    
    if [[ "$dry_run_check" -eq 1 ]]; then

        remove_pkg+=("${DRYRUN_FLAG[@]}")

    fi


    if [[ "$no_confirm_check" -eq 1 ]]; then

         remove_pkg+=("${NO_CONFIRM_FLAG[@]}")

    fi


    for pkg in "${pkgs[@]}"; do

        #-debug 
        #printf "DEBUG: %s\n" "${remove_pkg[*]} $pkg"


       "${remove_pkg[@]}" "$pkg"
       local status="$?"

        if [[ $status -eq 0 ]]; then
         
            \printf "[SUCCESS] Package '%s' has been removed\n" "$pkg" >> "$log_success"
        
        else

            \printf "[ERROR] Package '%s' has not been removed\n" "$pkg" >> "$log_failure"

        fi
            
    done


    set_space
    print_temp_file || return "$?"
    set_space
    cleanup || return "$?"

    return 0


}




usage(){


    \printf "
    
    Finzell's Unified Linux Kernel Package Management Resolver - a Unified Package Management Tool for Bash & zShell compatible with Linux & MacOS

    \tUsage: fkr <Flag> <Packages> || fkr <Flag> <Flag> ... <Packages> || fkr <Flag> <Flag> ...

    \t\t-> fkr -i <Packages> || --install <Packages> | Installs the desired packages
    \t\t-> fkr -r <Packages> || --remove  <Packages> | Removes the desired packages
    \t\t-> fkr -is <Packages> || --install-standard <Package> Installs the desired packages in batch-order, foregoing the installation one-at-a-time 
    \t\t-> fkr -rs <Packages> || --remove-standard <Package> Removes the desired package in batch-order, foregoing the removal one-at-a-time
    
    \t\t\t<Options> 
    \t\t\t\t-> --dry-run | This will carry-out a dry-run of the above specified-operation
    \t\t\t\t-> --noconfirm || -y | This will carry-out the above specified-operation without asking for Y/N input from the User
    \t\t\t\t-> --from-file <File> | This will carry-out the above specified-operation taking packages as input from a specified file
    
    \t\t-> fkr --query-pkg <Packages> || -qp <Packages> | Query the System-Installed packages
    \t\t-> fkr --query-repo <Packages> || -qr <Packages> | Query the Package Manager's Repository
    
    \t\t\t<Options>
    \t\t\t\t-> --from-file <File> | This will carry-out the above specified-operation taking packages as input from a specified file

    \t\t-> fkr --update | This will update the system's Package Manager's Repository

    \t\t-> fkr --upgrade | This will upgrade the system and packages 
    \t\t-> fkr --update-upgrade || -uu | This will Update & Upgrade the Repo and System
    
    \t\t\t<Options>
    \t\t\t\t-> --noconfirm || -y | This will carry out the above specified-operation without asking for Y/N input from the User 

    \t\t-> fkr --help || fkr -h | This will bring up the Usage 
    \t\t-> fkr --display-package-manager || -dpm | This will show the Package Manager being used by the system

    "


}




fkr_main(){

  
    trap 'cleanup >/dev/null 2>&1' EXIT INT TERM
    

    local arg="$1"

    case "$arg" in


        #if $2 is --from-file, then install from file
        --install | -i)
            
            shift
            install_packages "$@" || return "$?"

        ;;


        --install-standard | -is)

          shift
          install_packages_standard "$@" || return "$?"

        ;;

         #if $2 is --from-file, then remove from file
        --remove | -r)

            shift
            remove_packages "$@" || return "$?"

        ;;

        
        --remove-standard | -rs)

            shift
            remove_packages_standard "$@" || return "$?"

        ;;

        
        --query-pkg | -qp)
              
            shift
            query_pkg "$@" || return "$?"

        ;;

        
        --query-repo | -qr)

            shift
            query_repo "$@" || return "$?"

        ;;

        
        --update)
      
            if (($# != 1)); then

              \printf "\n[ERROR] Invalid flags!\n\n"
              return 8

            fi
            
            update_repo || return "$?" 

        ;;

        
        --upgrade)

            shift
            upgrade_packages "$@" || return "$?"

        ;;

      
        --update-upgrade | -uu)

            shift
            update_repo || return "$?"
            upgrade_packages "$@" || return "$?"

        ;;

  
        --display-package-manager | -dpm)

          if (($# != 1)); then
            \printf "\n[ERROR] Invalid flags!\n\n"
            return 8
          fi 

          display_package_manager || return "$?"

        ;;


        --help | -h)

          if (($# != 1)); then

            \printf "\n[ERROR] Invalid flags!\n\n"
            return 8
          
          fi

            usage || return "$?"

        ;;
        
        *)
           
          \printf "\n[ERROR] Invalid argument!"
            clear_space
            usage
            return 8

        ;;

    esac    
    
    return 0

}


fkr_main "$@"
