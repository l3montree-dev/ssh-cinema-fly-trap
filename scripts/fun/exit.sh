#!/bin/sh

/bin/echo -n "Enter 'im not allowed to be here' to confirm: "
read answer

if [ "$answer" != "im not allowed to be here" ]
then
    echo So indecisive...
    command exit 1
fi

echo I know...
/bin/echo -n "Where are you from? "
read answer
command exit 1