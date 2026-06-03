# This File is relative to ./../Main, so best to use Absolute Paths in Volumes default configuration, or use the path variable $CONTAINTER_SCRIPTS_DIRECTORY to specify the path to here! 
CONTAINER_SCRIPTS_DIR="$MAIN_DIR/../Container_Scripts"
ENVIRONMENT_SETUP_SCRIPTS_DIR="$CONTAINER_SCRIPTS_DIR/Environment_Setup_Scripts"
ENVIRONMENT_SCRIPTS_DIR="$CONTAINER_SCRIPTS_DIR/Environment_Scripts"
LOGS_DIR="$MAIN_DIR/../Logs"

FKR_DIR="$MAIN_DIR/../Scripts/FKR"
###############################################
##Global Fallback Defaults##
#This is a file to configure Defaults!


SKIP_RUNTIME_CHANGES=true

LABEL="ubuntu_env"

#-Rootless-#
#--Run Containers Rootless or Rootful
#--Usage: Boolean - must be 'true' or 'false'
ROOTFUL=true


#-Number of Containers-#
#--The number of containers to create - warning: must be 1 or more
#--Usage Example: NO_OF_CONTAINERS=1
NO_OF_CONTAINERS=311


#-Distros-#
#--The absolute Default in the case where no Distros are inputted by the User will be the first entry in the array! Warning: must be 1 or more
#--Usage Example: DISTROS=('<Distro_Name_1>' '<Distro_Name_2>' '<Distro_Name_3>')
DISTROS=(
    "ubuntu" 
)


#-Network-#
#--Networks to be used with the containers! Can be commented out, and will default to "none"!
#--Usage Example: NETWORK="podman" NETWORK="none" NETWORK="cni" #NETWORK="slirp4netns"
NETWORK="podman"


#-Volume-#
#--Volumes to be mounted on startup! Can be commented out!
#--Alternitavely, if using Selinux, add :z or :Z to the end!
#--Usage Example: VOLUMES=("<VOLUMES_Name_1>:<VOLUME_MOUNT_PATH_INSIDE_CONTAINER_1>" "<VOLUMES_Name_2>:<VOLUME_MOUNT_PATH_INSIDE_CONTAINER_2>"
VOLUMES=(
    "$LOGS_DIR:/app/logs" 
    "$CONTAINER_SCRIPTS_DIR/Environment_Scripts:/app/Environment_Scripts"
    "$FKR_DIR:/app/FKR"
)

INTERACTIVE_TERMINAL="false"


#-Device-#
#--Devices to be passed-through to the Container! Can be commented out!
#--Usage Example: DEVICES=("<HOST_DEVICE_Name1>:<CONTAINER_DEVICE_Name1>:<Permissions>" "<HOST_DEVICE_Name2>:<CONTAINER_DEVICE_Name2>:<Permissions>")
#DEVICES=(
#    "/dev/disk0s2:/dev/disk0s2:r"
#)

#-Pod-#
#--Set up a Pod upon Container Creation
#--Usage Example: POD=true or POD=false
POD=false

#-Pod Name-#
#--Set up a Pod upon Container Creation
#--Usage Example: POD_NAME="Backend"
POD_NAME="test"

POD_PORTS=(
    "8080:80"
    )

#-Startup Script-#
#--Startup Script to be ran for Environment Setup! Can be commented out!
#--Usage Example: STARTUP_SCRIPT="/PATH/TO/SCRIPT/script_name.sh"
STARTUP_SCRIPT="$ENVIRONMENT_SETUP_SCRIPTS_DIR/setup_env_example.sh"