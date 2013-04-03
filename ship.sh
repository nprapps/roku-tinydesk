#!/bin/sh

APP_NAME="roku-tinydesk"
ZIP_NAME="roku-tinydesk.zip"
VERSION="$1"

time=" `date +%s`"

output="`curl -s -S -F "mysubmit=Package" -F "app_name=$APP_NAME-$VERSION" -F "passwd=$ROKU_PASSWORD" -F "pkg_time=" http://$ROKU_IP/plugin_package`"

path="`echo $output | sed 's/.*\(pkgs\/.*\.pkg\).*/\1/'`"

curl --output "$APP_NAME-$VERSION.zip" http://$ROKU_IP/$path

