Initial Install:

loadkeys uk
curl -sL https://bit.ly/2U63Mf7 | bash
./alis.sh

Config Script:
curl -sL https://bit.ly/30XKeuI | bash


you may have to re-run some of the config section of the script manually from a console. (working on it)
to enable teamviewer at system startup:


login or su as ROOT
run:    teamviewer setup
follow the prompts and then reboot - you will now have teamviewer access at boot without any user having to log in (useful if you need to reboot remotely)
