#! /bin/bash

tofu apply -auto-approve
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
