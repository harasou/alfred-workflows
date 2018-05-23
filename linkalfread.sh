#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0);pwd)

LIB="$HOME/Library/Application Support/Alfred 3/Alfred.alfredpreferences/workflows"
cd "$LIB" || exit 2

for wf in GeoIP2 Munin PasswordPaster RunSSH ScreenCapture
do
    printf "%-15s ... " $wf 
    if [ -e $wf ] ; then
        echo skip.
    else
        ln -fs "$SCRIPT_DIR/$wf" $wf && echo ok || echo error
    fi
done
