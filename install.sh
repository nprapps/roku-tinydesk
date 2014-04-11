#!/bin/sh

ZIP_NAME="roku-tinydesk.zip"

./uninstall.sh

rm $ZIP_NAME;
zip $ZIP_NAME -r -9 . -i "source/*" -i "images/*" -i "manifest"

curl -s -S -F "mysubmit=Install" -F "archive=@$ZIP_NAME" -F "passwd=" --digest --user rokudev:$ROKU_PASSWORD http://$ROKU_IP/plugin_install 
