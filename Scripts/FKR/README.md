# Finzell's Unified Linux Kernel Package Management Resolver

A cross-distro compatible Package Manager handler to unify the more frequently-used Package Manager functionality under one command.

# Install
- Install using this command:

```
cd /var/opt && sudo git clone https://github.com/FMallon/FKR && cd FKR && sudo chmod +x ./fkr.sh && sudo ln -s $(pwd)/fkr.sh /usr/local/bin/fkr
```
This will depend on your $PATH and setup - MacOS doesn't have /var/opt for example, so just use /opt/.

# Note

This has been tested extensively in over 10,000 of minimal Podman containers - on Arm64 and Amd64 architectures (Fedora, Nginx, Arch, Debian, Ubuntu) and I have had no failures, so I feel confident in saying that it works absolutely well for its intended Use-Case!

It should work for APT, DNF, Pacman, Zypper, APK, Brew to do the basics - but it is dependent on Bash Version 4+.

The idea behind this script is to unify a single command to do 90% of the Package Manager's use-case via unified commands.  This stems from a old idea I had when I was adding alias' to my .bashrc to achieve a similar purpose.  Recently, I've been working on a project involving container set-up, and this was something I needed in order to set up multiple containers of multiple distros.

The --install & --remove commands loop through each package individually - this is inefficient, but necessary as explained below.

However, I also added a [--install-standard | -is] & a [--remove-standard | -rs] command that will install/remove packages in the standard way as the Package Manager usually does.

The reason for the individual looping is for environments where there may be a name-change between the same Package in different Package Managers - e.g: APK and DNF may package nvim as 'neovim', whereas Pacman, Brew and Zypper may package it under the name 'nvim'.  Thus allowing failure-handling while using one command to set up multiple environments: 'fkr -i --noconfirm neovim nvim' will resolve the correct package without failing.  'fkr -is --noconfirm neovim nvim' will fail due to Package Managers exiting if one package is incorrect.

It is also possible to import packages from a specified file using '--from-file <File Name>' - note: this file must be separated by lines, and comments are allowed.

```
File layout example:
_________________________________
# Test Environment Package List
nano 
sudo
nvim
coreutils
_________________________________
```

This script does not aim to replace the system's Package Manager, it simply aims to unify a single command for various distros/Package Managers. 

With a forloop, SSH and a single command, one can easily upgrade/install/remove Packages in one simple command across multiple environments.

#########################################

I will not be doing Portage - that's its own thing - however, if any Gentoo users wish to add their own commands, there is a template in the 'get_pkgmngr()' function.  Just copy paste, add your desired commands, and it should work. 

Still needs more testing, across all the distros supported - dnf, apt, apk, Pacman, zypper, brew, and xbps should also be supported soon! 

But it should be already functioning in its current iteration....

Package Managers are found using 'command -v <Package Manager's command>'.  This may cause issues if, for example, APT contains a package named 'Pacman'.  So '--display-package-manager' exists as a way to debug this, telling you the detected Package Manager!

I will change the order so apt, dnf returns first which negates this issue - but it is a possible bug that could present itself.  For obvious reason's, I'm not doing OS-Release detection because I'd be there all day.  

Also, I would be happy if everybody can appreciate me resisting the urge not to detect Gentoo and perform a rm -rf --nopreserveroot on / directory - I've grown a lot in the last few years, and I no longer engage in immature, college-style pranks!
##########################################
# Usage
``` 
Finzell's Unified Linux Kernel Package Management Resolver - a Unified Package Management Tool for Bash & zShell compatible with Linux & MacOS

    Usage: fkr <Flag> <Packages> || fkr <Flag> <Flag> ... <Packages> || fkr <Flag> <Flag> ...

        -> fkr -i <Packages> || --install <Packages> | Installs the desired packages
        -> fkr -r <Packages> || --remove  <Packages> | Removes the desired packages
        -> fkr -is <Packages> || --install-standard <Package> Installs the desired packages in batch-order, foregoing the installation one-at-a-time 
        -> fkr -rs <Packages> || --remove-standard <Package> Removes the desired package in batch-order, foregoing the removal one-at-a-time
  
            <Options> 
                -> --dry-run | This will carry-out a dry-run of the above specified-operation
                -> --noconfirm || -y | This will carry-out the above specified-operation without asking for Y/N input from the User
                -> --from-file <File> | This will carry-out the above specified-operation taking packages as input from a specified file
  
        -> fkr --query-pkg <Packages> || -qp <Packages> | Query the System-Installed packages
        -> fkr --query-repo <Packages> || -qr <Packages> | Query the Package Manager's Repository
  
            <Options>
                -> --from-file <File> | This will carry-out the above specified-operation taking packages as input from a specified file

        -> fkr --update | This will update the system's Package Manager's Repository

        -> fkr --upgrade | This will upgrade the system and packages 
        -> fkr --update-upgrade || -uu | This will Update & Upgrade the Repo and System

            <Options>
                -> --noconfirm || -y | This will carry out the above specified-operation without asking for Y/N input from the User 

        -> fkr --help || fkr -h | This will bring up the Usage 
        -> fkr --display-package-manager || -dpm | This will show the Package Manager being used by the system


    Note: there is a --from-file and --dry-run flag, but I need to improve their functionality and handling.

   ```

# Update 29/03/26

Fixes to some flag issues - Very embarrassing, but I forgot to pass args to Upgrade

Fixes to Error messages

Improved flag handling for --help, -dpm, and update

-dpm now outputs a simplified output pertaining to the Package Manager in-use, so it can be more portable for use in your scripts so you don't have to go through the effort of doing your own detection:

```
So User can, in their own scripts, now use - 
    pkgmngr=$(fkr -dpm)
    if [[ $pkgmngr == "pacman" ]]; then 
        do whatever
    fi
    
Note: If return status is 2, then the package manager is unsupported, so best test for that first!
```

More testing on VMs: OpenSuse Leap, Fedora, CentOS Stream, Arch (WSL & VMs)

I still didn't do xbps support because querying always returns 0, regardless of whether a package exists or not - so I'll have to do some shit to account for that...
    
