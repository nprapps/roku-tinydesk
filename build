#!/bin/sh

ROKU_IP="10.0.1.2"
ZIP_NAME="nproku.zip"

curl -s -S -F "mysubmit=Delete" -F "archive=" -F "passwd=" http://$ROKU_IP/plugin_install

rm $ZIP_NAME;
zip $ZIP_NAME -r -9 . -x ".git/*"

curl -s -S -F "mysubmit=Install" -F "archive=@$ZIP_NAME" -F "passwd=" http://$ROKU_IP/plugin_install
