#!/usr/bin/env bash


PACKAGES=(
    "nano" 
    "testdisk" 
    "nvme-cli"
    "coreutils"
    "hdparm"
    "git"
    "binutils"
    "util-linux"
    "ent"
    )


create_logfile(){

    log_file="/app/logs/$(uname -n)_log.log"
    touch "$log_file"

}


initialize_fkr(){

    local fkr="/app/FKR/fkr.sh"
    chmod 777 "$fkr"
    
    ln -s "$fkr" /usr/local/bin/fkr

}

update_container(){

    #This will update the container's Repo, and upgrade any packages that need upgrading

    fkr -uu --noconfirm 2>&1 | tee -a "$log_file"

}


install_packages(){

    fkr -i --noconfirm ${PACKAGES[*]} 2>&1 | tee -a "$log_file"

}

create_dir_git(){

    mkdir /git/ 2>&1 | tee -a "$log_file"

}

init_git_packages(){

    local github_link="https://github.com"
    local log_append_dir=/git/LogAppend
    local log_command_dir=/git/LogCommand

    git clone "$github_link/FMallon/LogAppend" "$log_append_dir"
    git clone "$github_link/FMallon/LogCommand" "$log_command_dir"

    chmod 777 "$log_append_dir/log_append.sh"
    chmod 777 "$log_command_dir/log_command.sh"

    ln -s "$log_append_dir/log_append.sh" /usr/local/bin/log
    ln -s "$log_command_dir/log_command.sh" /usr/local/bin/logcom

}

begin_test(){

    log -b "$log_file"
    logcom "echo 'Hello'" | log -a "$log_file" 
    log -e "$log_file"
}


main(){

    create_logfile
    initialize_fkr
    update_container
    install_packages
    create_dir_git
    init_git_packages
    begin_test
}

main
