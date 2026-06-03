#!/usr/bin/env bash

# This example script can be used to further fine tune specific containers by name absed on needs.
# You can call this in the Startup Script after the environments have been equally set-up as required.

print_name(){

    printf "\n[EXAMPLE.SH] This is %s calling from the example.sh script\n" "$PODBOI_NAME" >> "$LOG_FILE" 

}


print_env(){


    printf "\n[EXAMPLE.SH] I am %s in environment %s. From Image '%s'\n" "$PODBOI_NAME" "$PODBOI_LABEL" "$PODBOI_IMAGE" >> "$LOG_FILE" 



}


individual_container_setup_example(){

    case "$PODBOI_NAME" in

        test_env_1)
            # Here other functions can be performed to fine tune specific environments on an indivual level
            print_name

        ;;

        test_env_2)

            print_name

        ;;

        default_env_3)

            print_name

        ;;

    esac

}

individual_env_setup_example(){

    case "$PODBOI_LABEL" in

        test_env)
            # Here other functions can be performed to fine tune specific environments on an indivual level
            print_env

        ;;

        default_env)

            print_env

        ;;

    esac

}

example_main(){

    individual_container_setup_example
    individual_env_setup_example

}

example_main