<div align="center">

# PodBOI

### The Podman Bash Orchestration Infra-Tool

Portable container orchestration tool written entirely in Bash

_Minimal • Auditable • YAML-Free • Bash-First_

</div>

---

## Description

PodBOI is a container orchestration infra-tool written entirely in Bash.

It is portable, minimal, auditable, and designed for environments where simplicity, control, and reduced attack-surface matter more than layering additional tooling on-top of Podman.

## Features

- Environment-based container management
- Rootful and Rootless support
- Pod support
- Environment switching
- Cross-container command execution
- File distribution across environments
- Optional FKR integration
- Pure Bash implementation
- No YAML
- No Compose
- Minimal dependencies

## Note

As with everything I upload, it exists in a fully functional state.  This tool has been tested in Environments of over 10,000 concurrently running containers on my personal machine.  

PodBOI has also been tested completely setting-up over 60,000 containers during its development and testing stages.  This is being made public so I can begin testing in VMs of other environments.  

Basically: it works on my machine!

---

## Contents

- [About](#about)
- [FKR Integration](#fkr-integration)
- [Installation](#installation)
- [Commands](#commands)
- [Environment Management](#environment-management)
- [Export Variables](#export-variables)
- [Philosophy](#philosophy)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Architecture](#architecture)
- [Return Codes](#return-codes)
- [Config File](#config-file)


---

# About

PodBOI is a container orchestration infra-tool written entirely in Bash.

It is portable, minimal, auditable, and designed for environments where simplicity, control, and reduced attack-surface matter more than layering additional tooling on-top of Podman.

PodBOI exists for Minimal/HPC/Secure environments where tools such as Kubernetes, Ansible, Terraform, Compose, Helm, YAML templating systems, and other orchestration layers are often unnecessary overkill. These tools can introduce additional packages, binaries, libraries, abstractions, licencing, and security concerns that are not always justified for smaller or medium-scale container infrastructure.

PodBOI instead uses Bash itself as the orchestration language.

Using standard Bash features such as arrays, mapfiles, loops, functions, variables, conditionals, and shell scripting, environments can be declaratively defined and manipulated without relying on YAML-based configuration systems that lack native logical operations.

With a single config file and startup script, users can spin-up repeatable ephemeral environments or maintain long-running persistent environments entirely through Bash.

PodBOI has been tested with environments of over 3000 containers concurrently. In real-world testing, the primary limitations encountered were:

- OCI runtime limits
- Kernel keyring limits
- Aardvark DNS/network exhaustion
- Registry/package-manager rate limits
- Machine hardware limitations

If the underlying system is tuned correctly, PodBOI itself does not impose artificial scaling limitations.

PodBOI environments are manipulated using simple commands:

```bash
podboi --exec all echo hello
podboi --stop all
podboi --copy all file.txt /app
podboi --kill dev_env_12
```

Entire environments can be controlled in only a few words.

---

## FKR Integration

PodBOI ships with FKR:

https://github.com/FMallon/FKR

FKR is a fully portable package-manager detection utility written entirely in Bash.

It detects the package manager inside a container and automatically performs package operations using the correct commands for the target distribution. This allows startup scripts to remain portable across mixed container environments.

For example:

- Arch Linux
- Debian
- Ubuntu
- Fedora
- Alpine (as long as Bash is installed in the image)
- openSUSE

can all be initialized using the same startup logic.

FKR is mounted and initialized by default in the example PodBOI configuration and startup scripts.

However, PodBOI does not force this workflow.

If users do not wish to use FKR, they can simply:

- remove the mounted volume
- not include it in their startup script

The environment belongs entirely to the user.

---

## Environment Management

PodBOI environments are separated using labels.

This allows users to:

- create multiple isolated environments
- switch between environments
- temporarily target other environments
- manage grouped containers as a single logical unit

It is also possible to create environments where all containers communicate together within the same Pod.

Containers are named deterministically using the User's defined environment label:

```text
web_dev_1
web_dev_2
web_dev_3
```

This avoids Podman's randomly-generated container names and makes scripting significantly easier.

No longer will one have to type 'podman rm -f elaborate_chebyshev' or 'podman copy filename beneficent_stalin:destination' - or whatever the random nomenclature defines - into their terminal again!

All PodBOI-managed containers are additionally tagged using the hidden label:

```text
PodBOI.Managed=true
```

This separates PodBOI-managed infrastructure from unrelated Podman containers already present on the host system.

---

# Installation

Go to your directory of choice to download the project.
This uses sudo, but if you use doas, just change that one out.

Github:
 
 ```bash
 git clone https://github.com/FMallon/PodBOI && chmod -R 755 ./PodBOI && sudo ln -sf $(pwd)/PodBOI/Main/podboi.sh /usr/local/bin/podboi 
 ```

Forgejo:
 
 ```bash
  git clone https://v14.next.forgejo.org/FMallon/PodBOI && chmod -R 755 ./PodBOI && sudo ln -sf $(pwd)/PodBOI/Main/podboi.sh /usr/local/bin/podboi 

 ```

This assumes setting it up in a User's home directory, but should one wish to set-up on a dedicated server for use amongst multiple Users:
 1. clone it into the desired location
 2. manage the permissions - all files will need rw for all Users, and the PodBOI/Main/podboi.sh file will need executable permissions
 3. Create the Symlink into a directory in $PATH 

---

# Commands

## General

### `-h`, `--help`

Display help information.

### `--restore-default-config`

Restore the default PodBOI configuration.

### `--get-env`

Display the currently active environment.

### `--switch-env <env>`

Switch to another environment.

#### Example

```bash
podboi --switch-env dev_env
```

### `--env <env> <command>`

Run a command in a temporary environment without switching permanently.

#### Example

```bash
podboi --env dev --exec all ls
```

### `--is-root`

Displays the current PodBOI environment Rootful/Rootless state.

### `--print-env-vars`

Print all variables for the currently active environment.

---

## Container Management

### `-c`, `--create [--config]`

Create containers using the current environment configuration.

#### Example

```bash
podboi -c
```

### `--start <name|all>`

Start one container or all containers in the current environment.

#### Examples

```bash
podboi --start dev_env_1
```

```bash
podboi --start all
```

---

### `--stop <name|all>`

Stop one container or all containers in the current environment.

#### Examples

```bash
podboi --stop dev_env_1
```

```bash
podboi --stop all
```

---

### `--kill <name|all>`

Force-stop one container or all containers in the current environment.

#### Examples

```bash
podboi --kill dev_env_1
```

```bash
podboi --kill all
```

---

### `--remove <name|all>`

Remove one container or all containers in the current environment.

#### Examples

```bash
podboi --remove dev_env_1
```

```bash
podboi --remove all
```

---

### `--full-prune`

Kill and remove all containers belonging to the current environment.

#### Example

```bash
podboi --full-prune
```

---

## Container Interaction

### `--exec <name|all> <command>`

Execute a command inside one container or all containers in the environment.

#### Examples

```bash
podboi --exec dev_env_1 bash
```

```bash
podboi --exec all uname -a
```

---

### `--copy <name|all> <source> <destination>`

Copy files into one container or all containers.

#### Examples

```bash
podboi --copy dev_env_1 ./file.txt /tmp/file.txt
```

```bash
podboi --copy all ./script.sh /tmp/script.sh
```

---

### `-a`, `--attach <name>`

Attach to a running container.

#### Example

```bash
podboi --attach dev_env_1
```

---

## Information

### `-dc`, `--display-containers`

Display all PodBOI-managed containers - this will show all Rootless or all Rootful depedning on your current environment.

#### Example

```bash
podboi --display-containers
```

---

### `-ec`

Print container IDs only.

Useful for scripting and automation.

#### Example

```bash
podboi -ec
```

---

## Pod Management

### `--pod-start <pod_name>`

Start a Pod.

#### Example

```bash
podboi --pod-start dev
```

---

### `--pod-stop <pod_name>`

Stop a Pod.

#### Example

```bash
podboi --pod-stop dev
```

---

### `--pod-kill <pod_name>`

Force-stop a Pod.

#### Example

```bash
podboi --pod-kill dev
```

---

### `--pod-remove <pod_name>`

Remove a Pod.

Pods must first be stopped or killed.

#### Example

```bash
podboi --pod-remove dev
```

---

### `--pod-status <pod_name>`

Display Pod status information.

#### Example

```bash
podboi --pod-status dev
```

---

### `--pod-display`

Display all Pods managed by PodBOI.

**Note:** Results depend on your current Rootful/Rootless state.

- If `--is-root` reports Rootless, only Rootless Pods will be shown.
- On macOS, Podman may display both Rootful and Rootless Pods due to the quirks of Podman's virtualization layer.

#### Example

```bash
podboi --pod-display
```

---

## Notes

- Containers are grouped by labels.
- Container names are automatically generated as:

```text
<label>_<id>
```

- Rootful and Rootless Podman environments are separate.
- Pods are optional and can be used as an additional grouping layer.
- Most commands support targeting a specific container or `all`.
- `-ec` is intended primarily for scripting and automation.

## Export Variables

During container creation, PodBOI injects several exported environment variables into containers:

```bash
$PODBOI_LABEL
$PODBOI_NAME
$PODBOI_IMAGE
```

These variables allow:

- external scripts
- startup scripts
- injected automation
- container-specific logic

to dynamically determine:

- which environment they belong to
- which container they are
- which image they were built from

This makes container-specific tuning and environment-aware scripting straightforward using standard Bash logic such as `case` statements.

---

## Philosophy

PodBOI intentionally avoids unnecessary abstraction layers.

The goal is not to replace Kubernetes.

The goal is to provide a lightweight, transparent, Bash-native orchestration layer for users who:

- prefer auditable tooling
- want direct control
- work in minimal environments
- dislike YAML-heavy infrastructure
- need reproducible container environments without large orchestration stacks
- wish to set-up containers using more complex operands and logic unachievable using YAML

Everything is intentionally built around standard Bash and Podman primitives.

The current standard has been a push towards Infrastructure as YAML under the guise of "Infrastructure as Code", removing the capability of logical operations, stacking dependancies and tooling which seems to be pushing for the need for more overhead, tooling and licenses, which then adds more security concerns, as well as extra languages on top of YAML to execute more YAML.

This tool was built more-so as a proof of concept against all of the above, as Bash is - in-and-of-itself - very powerful, pervasive on most systems, auditable, has stood the test of time and will continue to do so.

And also proof of the lengths to which I am willing to go in-order to not indent another YAML file ever again.

No generated YAML.
No templating engines.
No hidden orchestration layers.
No dependency explosion.

Just Bash and containers.

---

# Quick Start

## Container_Scripts Directory

Everything a User normally needs to modify exists inside:

```text
./Container_Scripts
```

This includes:

- Config files
- Startup scripts
- Environment scripts

The default config used when no `--config` argument is provided also exists here.

Users are entirely free to:

- move configs elsewhere
- move startup scripts elsewhere
- create their own environment structures
- use completely custom paths

using:

```bash
podboi -c --config /path/to/config.sh
```

### Important

If creating custom configs or startup scripts, ensure they are:

- readable
- writable

for the User running PodBOI.

---

## Creating Your First Environment

First, change into the PodBOI directory:

```bash
cd PodBOI
```

Create the default environment:

```bash
yes n | podboi -c
```

This will create containers from the default config.

The `yes n |` pipe automatically answers `n` to the interactive prompt.

This interactive prompt allows a User to make changes at Run-Time, and can be skipped using 'SKIP_RUNTIME_CHANGES=true' in the config - more on this will be expanded upon in a different section.

### Notes

- `CTRL+C` or `CTRL+D` can be used to cancel safely
- if containers were accidentally created:

```bash
podboi --full-prune all
```

can be used to completely remove the current environment before restarting.

---

## Checking The Environment

Display the currently selected environment:

```bash
podboi --get-env
```

By default, this should output:

```text
default_env
```

provided nothing has been modified since cloning the repository.

Display whether the current environment is Rootful or Rootless:

```bash
podboi --is-root
```

The default example environment is Rootless.

---

## Creating Another Example Environment

PodBOI also ships with additional example configurations - mainly used by me for test purposes, but useful none-the-less.

Create another environment:

```bash
podboi -c --config ./Container_Scripts/Configs/config_test.sh
```
Note: we don't need to pipe into yes here because this config - should, as long as I remember - contain 'SKIP_RUNTIME_CHANGES=true'

Display all running containers:

```bash
podboi -dc
```

---

## Understanding The Example Environment

Both example environments call:

```text
./Container_Scripts/setup_env_example.sh
```

These environments also mount:

```text
./Logs
./Scripts/FKR
./Container_Scripts/Environment_Scripts
```

The startup script performs:

- FKR initialization
- package installation
- log creation
- environment setup
- secondary environment script execution

---

## FKR Integration

The example startup script initializes FKR inside the containers.

FKR is a portable package-manager detection utility written entirely in Bash.

Repository:

https://github.com/FMallon/FKR

This allows the same startup logic to work across multiple Linux distributions.

---

## Log Files

The example setup script writes logs per container into:

```text
./Logs
```

Each container receives its own logfile.

Example:

```text
default_env_1.log
default_env_2.log
test_env_1.log
```

etc.

The startup script exports the logfile path as:

```bash
$LOG_FILE
```

allowing all scripts to append cleanly to the same logfile.

This will be entirely upto you and your own default startup script to manage there - this is just my personal workflow

---

## Secondary Environment Scripts

The startup script also executes:

```text
./Container_Scripts/Environment_Scripts/example.sh
```

after the base environment has been initialized.

This demonstrates how environments can be further customized using standard Bash logic.

The example script uses:

```bash
case "$PODBOI_NAME" in
```

to apply logic only to:

```text
test_env_1
test_env_2
default_env_3
```

while leaving all other containers unchanged.

It also demonstrates environment-wide logic using:

```bash
case "$PODBOI_LABEL" in
```

---

## Viewing The Results

Inspect the generated logs inside:

```text
./Logs
```

If you check the final lines of:

```text
test_env_1.log
test_env_2.log
default_env_3.log
```

you will notice lines prefixed with:

```text
[EXAMPLE.SH]
```

These entries were generated by the secondary environment script.

The remaining containers will not contain these entries due to the conditional logic defined inside `example.sh`.

This demonstrates:

- container-aware scripting
- environment-aware scripting
- injected variable usage
- conditional execution

using only Bash.

---

## Example Log Output

Example output from `./Logs/default_env_3.log`:

```text
The Package Manager for this Image is: apt-get

[ubuntu] Hello, this is default_env_3. I am root.

[SUCCESS] Creating user1 Profile

[SUCCESS] Creating the test.txt file

[EXAMPLE.SH] This is default_env_3 calling from the example.sh script

[EXAMPLE.SH] I am default_env_3 in environment default_env. From Image 'ubuntu'
```

This demonstrates:

- successful FKR initialization
- package-manager detection
- startup script execution
- filesystem operations
- user creation
- injected environment variable usage
- secondary environment script execution
- container-aware and environment-aware logic

using only Bash.

---

## Manipulating Environments

Verify the current environment:

```bash
podboi --get-env
```

This should currently display:

```text
test_env
```

---

## Executing Commands

Execute a command across all containers in the current environment:

```bash
podboi --exec all echo hello world
```

---

## Temporary Environment Switching

Temporarily switch environments using `--env`:

```bash
podboi --env default_env --exec all echo hello world
```

This executes the command in `default_env` before automatically returning to the current environment.

---

## Copying Files

Copy `README.md` into a single container - assuming you are in the PodBOI directory:

```bash
podboi --env default_env --copy default_env_2 ./README.md /
```

Verify the file exists:

```bash
podboi --env default_env --exec default_env_2 bash -c 'cat /README.md | head -n 5'
```

---

## Copying Files Across Entire Environments

Copy `README.md` into all containers in the current environment:

```bash
podboi --copy all README.md /
```

Verify the file exists:

```bash
podboi --exec all bash -c 'cat /README.md | head -n 5'
```

---

## Cleaning Up Containers

Kill all containers in the current environment:

```bash
podboi --kill all
```

Remove all containers in the current environment:

```bash
podboi --remove all
```

Alternatively:

```bash
podboi --full-prune all
```

will perform both operations sequentially.

---

## Cleaning Another Environment

Switch environments:

```bash
podboi --switch-env default_env
```

Then fully remove the environment:

```bash
podboi --full-prune all
```

---

## Final Verification

After cleanup, verify that all containers were removed successfully:

```bash
podboi -dc
```

No containers should now be displayed.

---

# Architecture

PodBOI was built as a way to Spin-Up containers from a simple Config, with the option of quick run-time changes should the need arise.

All of this was done and working, and the underlying architecture was completed for my specific needs.

Initially, it was designed around creating quick, random, ephemeral containers for Testing Environments, as well as for Disk Sanitization for an old job I had where I needed to come up with a way to sanitize disks for re-use before shipping loan PCs to medical practitioners.

At the time, I had no access to actual Enterprise tools, and nobody wanted to spend 15k a year on a licence, etc.

Ultimately, I ended up doing some Sanitization work after leaving for Clients wishing to throw out old hardware, hence why I went all-in on this.

Therefore, the tool was built specifically for those needs.

This was done through a tool I built around an Arch Linux environment on an external SSD-USB setup.

This is why I chose Bash only - to diminish dependencies and keep auditability.

I then needed a way to upgrade, update, and install packages into a container regardless of the Image's distro.

So I made FKR.

FKR is a unified Package Manager management tool that performs the needs of 90% of Package Manager use-cases.

It installs packages sequentially to avoid naming issues as they relate to package names maintained by different Package Manager maintainers.

This is inefficient - but it was a way to avoid errors, thus allowing a User to enter multiple possible variations so they may install the same package on multiple distributions with a for loop, SSH set-up, and one command.

FKR does allow usual Package Manager installation using the `-is` flag.

This was a way to replace Ansible for me in some VMs and test environments where I was only using Ansible to update and upgrade systems.

I realized that I had set up:

* A User Account
* SSH
* Sudo privileges
* Python
* Extra dependencies

that I didn't even need.

This is also the reason FKR is one script of roughly a thousand lines of code.

I didn't want to break it down into a structured project as I usually would - purely to reduce failures due to files and folders not being implemented correctly, missing files, permission handling, etc.

I did not inject FKR automatically during container creation - I left this entirely to the User's discretion.

Hence why it must be mounted by volume and handled in the User's Startup Script - of which the provided Configs and setup scripts contain examples so one can simply copy and paste.

This was because I didn't want to force the User into additional tooling in their own container environments.

This is purely a philosophical view - but it does add slightly more work for the User, of which I could easily inject and set up FKR in roughly 6 extra lines of code during Creation.

A User could also easily:

* Copy the FKR script into all containers after creation
* Execute the command to set it up themselves
* Ignore it entirely if they wish

Though, I did automatically inject 3 export variables.

This was a compromise to allow easier container handling and to give a container some individuality, thus allowing Users to manipulate containers and environments through external scripts.

Of course, a User can export their own variables in the Container Startup Script that they manage.

I then began building the Command architecture around the Podman functionality:

* Executing commands
* Copying files
* Starting containers
* Killing containers
* Managing environments
* Managing Pods

For most functions, PodBOI will completely exit on the first issue.

This design choice was due to the fact that usually if one issue occurs - such as copying, executing or creating containers - the following containers will fail too.

I didn't want a for-loop of 1000 containers being executed with a possible 999 failures.

Functions are very verbose, and I use a lot of guard clauses and a "from first principles" style.

This is mainly because I prefer verbose functionality, avoid nested code, and was taught this way during WebDev lectures due to the nature of Javascript - although it didn't really click with me until recently.

This is purely a stylistic choice, as I don't like constantly hiding behind abstraction.

I did study Computer Science through Games Development, but did not complete my degree.

So I do not claim to be a Programmer, nor do I want to be.

I am purely an IT Technician / Sys-Admin.

I have opinions about abstraction, overhead, and OOP - but those opinions mean very little coming from me given the above information.

At that point, I had finished what I needed for my Use-Case.

However, I did add extra functionality for other Users after I realized the project was quite useful and capable of handling all the containers I threw at it.

In some tests this was over 3000 containers - only being limited by:

* Kernel keyring limits
* OCI Runtime limits
* Registry rate limits
* System resources
* PTY limits

I added Pod functionality after that, and ended up doing a large refactoring of the code from things I learned along the way.

I did at one point try to extend the project to include a Systemd implementation - but that didn't go as planned, and I was mostly developing from a MacOS machine.

The way Podman handles Systemd has changed over time, and I wasn't sure of the best implementation approach:

* Volume mounted cgroups
* Quadlets
* Other approaches

I may add this in the future depending on my needs or interest.

As of now, there are no plans to do so due to the fact that this project has already consumed months of work.

Therefore, some of the design decisions reflect my needs at the time:

* Random Distros
* Ephemeral Testing
* Declaritive Ephemeral Containers for Disk Sanitization

This is why Images are chosen at Random during creation.

If you want 1 container, and have:

* Arch
* Debian
* OpenSUSE
* Ubuntu

in the `IMAGES` array of the Config, the Image will be chosen at Random rather than simply selecting the first entry.

I also chose to handle containers serially rather than in parallel.

This reduces a lot of complexity:

* Possible collisions
* Additional error handling
* Synchronization concerns
* General implementation complexity

Especially as it pertains to large-scale container operations that I was doing during testing - spinning-up enviroments of over 10k containers.  In this case, I would suggest using a Pod so as to avoid any network issues related to Aardvark Exhaustion.  I would also suggest not using Pod Commands at this scale depending on your system as they may completely crash the system with CPU spikes and high RAM in performing such a huge parallel operation.  By using the '--full-prune all' command, it will inividually kill and remove containers - it will take awhile, but it won't break your system.  When this is finishes, you can kill the pod and remove it to completely get rid of it.

For such large operations, I also added an INTERACTIVE_TERMINAL boolean in the Configs so to negate PTY over-runs.

But running these operations on my personal PC was for testing and out of curiousity - and highly unnecessary.  That being said, should one wish to try it, my system specs are as follows:

  * CPU           - AMD Ryzen 9 9950X3D 
  * RAM           - 64gb CL32 
  * GPU           - AMD 9070XT OC
  * Storage       - 1 TB NVME , 4 TB NVME - (PCIe Gen 4)
  * Motherboard   - MAG X870 Tomahawk WIFI
  * Environment   - Arch Linux, Hyprland

So my PC usually sits at about 3-5gb of Memory Usage.

I have also set-up environments of around 800 containers on a MacOS Macbook Air - M5, 16gb RAM

## How it works

PodBOI uses Podman's label system to segment environments.  The name of each container will also be named in the format of '<label_number>'.  During the validation of the Config/User-Input stages of building an environment, there will be a validation check to make sure the environment (or label) is not already in use.  Then, during container creation, there will be another validation check to ensure none of the names of <label_number> are not taken, thus reducing rate of failure.  

The default config is naturally set to ./Container_Scripts/Configs.  For multiple environments, a User will have multiple configs, these other Configs can be stored anywhere - they are called using the 'podboi -c --config' flag.  As with everything in the Container_Scripts directory, they are entirely changeable, like the Setup Script that the User wishes to use, or any extra proceeding Environment Setup scripts.  But this Container_Scripts directory will be for the User to do with as they wish.  I have left some personal Configs that I have used as an example for ease-of-use, and some startup scripts, so a User can familiarize themselves with the tool.

When validation succeeds, the environment's variables are stored in a file of the environment's name in ./.local_podboi.  The currently chosen environment is stored in the ./.cache_podboi/podboi_env file.  The reasons that these are here and not in the User's home .local and .cache is 

    1. Localizing these files to the PodBOI directory can enable set-up on a dedicated machine for multiple users to access without complications - each User can be giving their own environment or dedicated container name.
    2. I prefer to touch as little of a User's system as is possible on my end.


## Why Bash

Bash is actually pretty good.  The syntax is disgusting; I wish there were variable assignment (I guess there is with declare... but it's not very aesthetic); I wish there were return types in functions; I wish I didn't have to write 'esac' to close a Case Statement.... But it's a powerful programming language. 

It's fast. Doesn't need maintaining every few months like Python.  Doesn't need to compile.  It exists on almost every Linux system.  If it works now, it will work 20yrs from now.  

As with all my projects, I do try to make them compatible with ZShell, hence why there are some artifacts in relation to this.  I actually still plan on making it zsh-compatible, and I do think it only requires changing the 'mapfile -t' with a zsh-compatible '("${(@f))...' - or something like that.  But when I did refactoring, I went Bash first, and exchanged readarrays for mapfiles, especially as it was pertaining to larger operations of over 1k containers. 
 
Bash is also far more reliable from a system's standpoint.  These projects seem to need more maintainence due to constant changes, to where a project made in Bash 20 years ago will likely work now.  They do go through loops faster, however, the pros out-weigh the cons, and the loops used in PodBOI seem to be constrained purely by the amount of time it takes to perform an OCI Runtime execution.  Bash has its limits... but if you treat it like just some glue-code, it will be percieved only as glue-code.  

Bash is as minimal as it gets in terms of any "libraries".  I consider libraries in Bash to be a Core-Utils binary like WC or Grep.  These are fast on Bash and come equipped on every system (mostly).

But mainly I like keeping things minimal.  I prefer keeping my systems minimal as a general principal.

--- 

# Return Codes

  * Return 1  - Error: Config File does not exist!
  * Return 2  - Error: Max User Input on Attempts Reached         
  * Return 3  - Error: Config Validation
  * Return 4  - Error: Validation Container/Pod Pruning
  * Return 5  - Error: Privilege escalation 
  * Return 6  - Error: Displaying Containers
  * Return 7  - Error: Stopping Containers
  * Return 8  - Error: Killing Containers
  * Return 9  - Error: Removing Containers
  * Return 10 - Error: Container Instance already exists!
  * Return 11 - Error: Copying into a Container
  * Return 12 - Error: Starting a Container
  * Return 13 - Error: Executing a Command into a Container
  * Return 14 - Error: Invalid Args || Invalid Args inside the "--env" function 
  * Return 15 - Error: Sourcing a file
  * Return 16 - Error: Executing a Command in the CLI
  * Return 17 - Error: Switching Environment
  * Return 18 - Error: Pod doesn't exist                                          
  * Return 19 - Error: Invalid Return Status in 'pod_exists' function
  * Return 20 - Error: Creating Pod
  * Return 21 - Error: Stopping/Killing the Pod
  * Return 22 - Error: Starting the Pod
  * Return 23 - Error: Removing the Pod
  * Return 24 - Error: Getting the Status of the Pod
  * Return 25 - Error: Creating a container
  * Return 26 - Error: Container isn't running - the command cannot run unless the specified container is running
  * Return 27 - Error: Container name exists elsewhere on the system
  * Return 28 - Error: Invalid Root Privileges
  * Return 29 - Error: Podman doesn't exist on the system - this being no. 29 and not 1 shows the level of confidence I have in you people <3
  * Return 30 - Error: Unsupported environment
  * Return 31 - Error: There was an issue during the User Input Pod Validation Check - duplicate ports detected    
  * Return 32 - Error: Invalid variable entry where the assignment an unexpected result - e.g. neither true nor false in a boolean assignment
  * Return 33 - Error: Attaching to a Container
  * Return 34 - Blocked: Attaching to a Container while $INTERACTIVE_TERMINAL=false

---

# Config File

PodBOI environments are defined entirely through Bash configuration files.

Each configuration controls how containers are created, grouped, initialized, and managed.

---

## Variables

### `SKIP_RUNTIME_CHANGES`

Boolean value that determines whether the Runtime Changes prompt is displayed during environment creation.

This is useful when automating container creation through scripts, CI pipelines, or other non-interactive workflows.

**Valid Values**

```bash
SKIP_RUNTIME_CHANGES="true"
SKIP_RUNTIME_CHANGES="false"
```

---

### `LABEL`

The environment label used to group containers.

This label becomes:

- the environment identifier
- part of the container name
- the value used for environment switching

Container names are automatically generated using:

```text
<label>_<id>
```

Example:

```text
dev_1
dev_2
dev_3
```

**Example**

```bash
LABEL="dev"
```

---

### `ROOTFUL`

Determines whether containers are created in Rootful or Rootless Podman mode.

**Valid Values**

```bash
ROOTFUL="true"
ROOTFUL="false"
```

**Example**

```bash
ROOTFUL="false"
```

---

### `NO_OF_CONTAINERS`

The number of containers to create for the environment.

Must be greater than zero.

**Example**

```bash
NO_OF_CONTAINERS=10
```

---

### `IMAGES`

Array of container images available during creation.

At least one image must be defined.

**Example**

```bash
IMAGES=(
    "ubuntu"
    "debian"
    "archlinux"
)
```

---

### `NETWORK`

Defines the network mode used by containers.

Ignored when `POD="true"`.

**Example**

```bash
NETWORK="podman"
```

Common values:

```text
podman
none
cni
slirp4netns
```

---

### `INTERACTIVE_TERMINAL`

Determines whether PodBOI allocates a PTY during container creation.

For extremely large environments, disabling this can help reduce PTY consumption.

**Example**

```bash
INTERACTIVE_TERMINAL="false"
```

---

### `VOLUMES`

Array of volumes mounted into each container.

SELinux users may append `:z` or `:Z` where appropriate.

**Example**

```bash
VOLUMES=(
    "/host/path:/container/path"
)
```

---

### `DEVICES`

Array of host devices passed through to containers.

Supports both simple and explicit device mappings.

**Examples**

```bash
DEVICES=(
    "/dev/nvme0n1"
    "/dev/nvme1n1"
)
```

```bash
DEVICES=(
    "/dev/nvme0n1:/dev/nvme0n1:rw"
)
```

---

### `POD`

Determines whether containers are created inside a Pod.

**Example**

```bash
POD="true"
```

---

### `POD_NAME`

Name assigned to the Pod when `POD="true"`.
If the Pod exists, the containers will be added to that - a warning will be given to the User first with a 7 second timer before proceeding

**Example**

```bash
POD_NAME="Dev"
```

---

### `POD_PORTS`

Array of Pod port mappings.

Only applies when Pods are enabled.

**Example**

```bash
POD_PORTS=(
    "8080:80"
    "8443:443"
)
```

---

### `STARTUP_SCRIPT`

Script executed after container creation.

Typically used for:

- package installation
- environment initialization/building
- user creation
- configuration
- FKR integration

**Example**

```bash
STARTUP_SCRIPT="$ENVIRONMENT_SETUP_SCRIPTS_DIR/setup_env_example.sh"
```

---

## Example Configuration

The following configuration creates:

- a Rootless environment
- 7 containers
- randomly selected Linux distributions
- mounted logs and scripts
- optional FKR integration
- no Pod usage

```bash
# Example config here...
```

---

## Example

```bash
# This File is relative to ./../Main, so best to use Absolute Paths in Volumes default configuration, or use the path variable $CONTAINTER_SCRIPTS_DIRECTORY to specify the path to here! 
CONTAINER_SCRIPTS_DIR="$MAIN_DIR/../Container_Scripts"
ENVIRONMENT_SETUP_SCRIPTS_DIR="$CONTAINER_SCRIPTS_DIR/Environment_Setup_Scripts"
ENVIRONMENT_SCRIPTS_DIR="$CONTAINER_SCRIPTS_DIR/Environment_Scripts"
LOGS_DIR="$MAIN_DIR/../Logs"

FKR_DIR="$MAIN_DIR/../Scripts/FKR"
###############################################
##Global Fallback Defaults##
#This is a file to configure Defaults!

#-Skip Runtime Changes-#
#This will skip the Runtime Changes Input section - useful for scripts
#--Usage Example: SKIP_RUNTIME_CHANGES=true; SKIP_RUNTIME_CHANGES=false
SKIP_RUNTIME_CHANGES="false"



#-Label-#
#--Set-up a unifying Label Name for the current environment instance being created
#--Usage Example: LABEL="dev"
LABEL="default_env"

#-Rootless-#
#--Run Containers Rootless or Rootful
#--Usage: Boolean - must be "true" or "false"
ROOTFUL="false"


#-Number of Containers-#
#--The number of containers to create - warning: must be 1 or more
#--Usage Example: NO_OF_CONTAINERS=1
NO_OF_CONTAINERS=7


#-Images-#
#--The absolute Default in the case where no Images are inputted by the User will be the first entry in the array! Warning: must be 1 or more
#--Usage Example: IMAGES=("<Image_Name_1>" "<Image_Name_2>" "<Image_Name_3>")
IMAGES=(

    "ubuntu"
    "debian"
    "fedora"
    "archlinux"
)


#-Network-#
#--Networks to be used with the containers! Can be commented out, and will default to "none"!
#--This will not be used if POD=true
#--Usage Example: NETWORK="podman" || NETWORK="none" || NETWORK="cni" || NETWORK="slirp4netns"
NETWORK="podman"


#-Interactive Terminal-#
#--Whether or not the Interactive Terminal will be used during creation
#--Usage Example: INTERACTIVE_TERMINAL="true" || INTERACTIVE_TERMINAL="false"
INTERACTIVE_TERMINAL="true"


#-Volume-#
#--Volumes to be mounted on startup! Can be commented out!
#--Alternitavely, if using Selinux, add :z or :Z to the end!
#--Usage Example: VOLUMES=("<VOLUMES_Name_1>:<VOLUME_MOUNT_PATH_INSIDE_CONTAINER_1>" "<VOLUMES_Name_2>:<VOLUME_MOUNT_PATH_INSIDE_CONTAINER_2>"
VOLUMES=(
    "$LOGS_DIR:/app/logs" 
    "$CONTAINER_SCRIPTS_DIR/Environment_Scripts:/app/Environment_Scripts"
    "$FKR_DIR:/app/FKR"
)


#-Device-#
#--Devices to be passed-through to the Container! Can be commented out!
#--Usage Example: DEVICES=("<HOST_DEVICE_Name1>:<CONTAINER_DEVICE_Name1>:<Permissions>" "<HOST_DEVICE_Name2>:<CONTAINER_DEVICE_Name2>:<Permissions>")
#--Alternatively you can forego the above format for: DEVICES=("<DEVICE_NAME_1>" "<DEVICE_NAME_2>")
DEVICES=(
)


#-Pod-#
#--Set up a Pod upon Container Creation
#--Usage Example: POD=true or POD=false
POD="false"

#-Pod Name-#
#--Set up a Pod upon Container Creation
#--Usage Example: POD_NAME="Dev"
POD_NAME="default"

#-Pod Ports
#--Set up a Pod's listening Ports
#--Usage Example: POD_PORTS=("8080:80" "8081:443")
POD_PORTS=(
    "8080:80"
    )

#-Startup Script-#
#--Startup Script to be ran for Environment Setup! Can be commented out!
#--Usage Example: STARTUP_SCRIPT="/PATH/TO/SCRIPT/script_name.sh"
STARTUP_SCRIPT="$ENVIRONMENT_SETUP_SCRIPTS_DIR/setup_env_example.sh"

```
