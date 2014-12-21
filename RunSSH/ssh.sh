#!/bin/bash

opts=$1

if [[ $opts =~ ^\[(.*)\]:([0-9]+)$ ]] ; then
  ssh -p ${BASH_REMATCH[2]} ${BASH_REMATCH[1]}
else
  ssh $opts
fi
