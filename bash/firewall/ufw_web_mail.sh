#!/bin/bash

# disable firewall
ufw disable

# deny all
ufw default deny

# allow for:
# Apache
ufw allow http
ufw allow https
# Mail
ufw allow smtp
ufw allow submission
ufw allow imaps
ufw allow pop3s
# SSH
ufw allow ssh
# DNS
ufw allow 53/tcp
ufw allow 53/udp

# enabe firewall
ufw enable
# show status
ufw status verbose