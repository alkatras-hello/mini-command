#!/bin/bash

TARGET="/usr/local/bin/py-line.sh"

if [ -f "$TARGET" ];  then
    echo " rm mini-command name py-line "
    sudo  rm "$TARGET"
    echo " comand deleted"
else
    echo "Error: comand py-line not found in /usr/local/bin/"


echo "thank you user"

fi
