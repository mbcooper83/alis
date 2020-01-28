#!/usr/bin/env bash
set -e

rm -f postinstallbin.sh

wget https://raw.githubusercontent.com/mbcooper83/alis/master/postinstallbin.sh
chmod +x postinstallbin.sh
sh ./postinstallbin.sh