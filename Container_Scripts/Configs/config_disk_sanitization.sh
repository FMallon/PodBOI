#!/usr/bin/env bash

# This File is relative to ./../Main, so best to use Absolute Paths in Volumes default configuration, or use the path variable $CONTAINTER_SCRIPTS_DIRECTORY to specify the path to here! 
CONTAINER_SCRIPTS_DIR="$MAIN_DIR/../Container_Scripts"
ENVIRONMENT_SETUP_SCRIPTS_DIR="$CONTAINER_SCRIPTS_DIR/Environment_Setup_Scripts"
ENVIRONMENT_SCRIPTS_DIR="$CONTAINER_SCRIPTS_DIR/Environment_Scripts"
LOGS_DIR="$MAIN_DIR/../Logs"


FKR_DIR="$MAIN_DIR/../Scripts/FKR"
###############################################

LABEL="disk_sanitization_env"
ROOTFUL=true
NO_OF_CONTAINERS=1
IMAGES=(
    "archlinux" 
)

NETWORK="podman"

INTERACTIVE_TERMINAL="true"


VOLUMES=(
    "$LOGS_DIR:/app/logs" 
    "$CONTAINER_SCRIPTS_DIR/Environment_Scripts:/app/Environment_Scripts"
    "$FKR_DIR:/app/FKR"
)

DEVICES=(
    #"/dev/nvme1n1:/dev/nvme1n1:rw"
    #"/dev/sdx:/dev/sdx:rw"
)

POD=false

POD_NAME=""

POD_PORTS=(
    )

STARTUP_SCRIPT="$ENVIRONMENT_SETUP_SCRIPTS_DIR/setup_disk_sanitization.sh"