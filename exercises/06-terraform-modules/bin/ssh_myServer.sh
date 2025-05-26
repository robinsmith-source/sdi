#!/usr/bin/env bash

GEN_DIR=$(dirname "$0")/../gen

ssh -o UserKnownHostsFile="$GEN_DIR/known_hosts" devops@157.180.66.96 "$@"