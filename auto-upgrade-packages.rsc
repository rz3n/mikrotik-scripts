# ------------------- header --------------------
# Script by Ricardo Franzen - rfranzen<at>gmail.com
# If you use this script, or edit and
# re-use it, please keep the header intact.
# Description: script to auto-upgrade packages
# Tested on: routeros v6.35
# ------------------- header --------------------

/system package update check-for-updates

:if ([/system package update get installed-version] != [/system package update get latest-version] ) do={
	:log warning "Upgrade packages from $[/system package update get installed-version] to $[/system package update get latest-version]";

	/system package update install
}