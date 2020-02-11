#!/usr/bin/env bash
set -e
wget https://raw.githubusercontent.com/mbcooper83/alis/master/postinstallbin.sh
chmod +x postinstallbin.sh
./postinstallbin.sh
rm postinstallbin.sh
