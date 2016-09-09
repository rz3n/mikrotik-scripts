# ------------------- header --------------------
# Script by Ricardo Franzen - rfranzen<at>gmail.com
# If you use this script, or edit and
# re-use it, please keep the header intact.
# Description: script to auto-upgrade routerboard
# Tested on: routeros v6.35
# ------------------- header --------------------

:if ([/system routerboard get current-firmware] != [/system routerboard get upgrade-firmware] ) do={
	:log warning "Upgrade routerboard from $[/system routerboard get current-firmware] to $[/system routerboard get upgrade-firmware]";

	/system routerboard upgrade
	:delay 300s;
	/system reboot
}