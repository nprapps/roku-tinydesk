#!/bin/sh

if [ $# -ne 1 ]
then
    echo "Usage: `basename $0` {version}"
    exit
fi

APP_NAME="roku-tinydesk"
VERSION="$1"
PKG_NAME="$APP_NAME-$VERSION"

time=" `date +%s`"

output="`curl -s -S -F "mysubmit=Package" -F "app_name=$PKG_NAME" -F "passwd=$ROKU_GENKEY_PASSWORD" -F "pkg_time=" --digest --user rokudev:$ROKU_PASSWORD http://$ROKU_IP/plugin_package`"

path="`echo $output | sed 's/.*href=\"\(pkgs\/\/.*\.pkg\)\".*/\1/'`"

curl --output "$PKG_NAME.zip" --digest --user rokudev:$ROKU_PASSWORD http://$ROKU_IP/$path

echo "Created $PKG_NAME.zip"
