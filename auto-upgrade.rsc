# ------------------- header --------------------
# Script by Ricardo Franzen - rfranzen<at>gmail.com
# If you use this script, or edit and
# re-use it, please keep the header intact.
# Description: generic functions to use in scripts
# Tested on: > routeros v6.36
# ------------------- header --------------------

:if ([/system package update get installed-version] != [/system package update get latest-version] ) do={
	:log warning "Upgrade: from $[/system package update get installed-version] to $[/system package update get latest-version]";

	/system package update install
}