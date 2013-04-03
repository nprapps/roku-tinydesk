#!/bin/sh

APP_NAME="roku-tinydesk"
VERSION="$1"
PKG_NAME="$APP_NAME-$VERSION"

time=" `date +%s`"

output="`curl -s -S -F "mysubmit=Package" -F "app_name=$PKG_NAME" -F "passwd=$ROKU_PASSWORD" -F "pkg_time=" http://$ROKU_IP/plugin_package`"

path="`echo $output | sed 's/.*\(pkgs\/.*\.pkg\).*/\1/'`"

curl --output "$PKG_NAME.zip" http://$ROKU_IP/$path

echo "Created $PKG_NAME.zip"
