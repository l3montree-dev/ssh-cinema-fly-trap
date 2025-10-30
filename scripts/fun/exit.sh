#!/bin/sh


    /bin/echo -n "Enter 'im not allowed to be here' to confirm: "
    read answer
    if [ "$answer" != "im not allowed to be here" ]
    then
        echo So indecisive...
        exit 1
    fi
