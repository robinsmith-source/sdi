#!/bin/sh

apt update && apt install -y nginx
apt install -y nginx
systemctl enable nginx
systemctl start nginx