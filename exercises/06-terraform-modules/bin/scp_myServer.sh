#!/usr/bin/env bash

GEN_DIR=$(dirname "$0")/../gen

if [ $# -lt 2 ]; then
   echo usage: .../bin/scp ... devops@157.180.66.96 ...
else
   scp -o UserKnownHostsFile="$GEN_DIR/known_hosts" $@
fi