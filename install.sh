#!/bin/sh

ZIP_NAME="roku-tinydesk.zip"

./uninstall.sh

rm $ZIP_NAME;
zip $ZIP_NAME -r -9 . -x ".git/*"

curl -s -S -F "mysubmit=Install" -F "archive=@$ZIP_NAME" -F "passwd=" http://$ROKU_IP/plugin_install
