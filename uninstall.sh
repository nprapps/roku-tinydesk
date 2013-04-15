#!/bin/sh

curl -s -S -F "mysubmit=Delete" -F "archive=" -F "passwd=" http://$ROKU_IP/plugin_install
