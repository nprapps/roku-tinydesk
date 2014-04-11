#!/bin/sh

curl -s -S -F "mysubmit=Delete" -F "archive=" -F "passwd=" --digest --user rokudev:$ROKU_PASSWORD http://$ROKU_IP/plugin_install
