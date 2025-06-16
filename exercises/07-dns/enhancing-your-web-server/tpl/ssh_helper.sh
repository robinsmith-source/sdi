#!/usr/bin/env bash

GEN_DIR=$(dirname "$0")/../gen

ssh -o UserKnownHostsFile="$GEN_DIR/known_hosts_for_server" ${user}@${ip} "$@"