# ------------------- header --------------------
# Script by Ricardo Franzen - rfranzen<at>gmail.com
# If you use this script, or edit and
# re-use it, please keep the header intact.
# Description: generic functions to use in scripts
# ------------------- header --------------------


# -----------------------------------------------
# Set default route distance in a pppoe interface
# ex. $setDistPppoe ifNum=[pppoe interface number] dist=[distance]
:global setDistPppoe do={
	:if ([/interface pppoe-client get number=$ifNum default-route-distance] != $dist) do={
		/interface pppoe-client set default-route-distance=$dist numbers=$ifNum
	}
}


# -----------------------------------------------
# Disable and enable pppoe interface
# ex. $pppoeReconnect ifNum=[pppoe interface number]
:global pppoeReconnect do={
	/interface pppoe-client disable $ifNum
	/interface pppoe-client enable $ifNum
}


# -----------------------------------------------
# Set default route distance in a dhcp-client item
# ex. $setDistDhcp ifNum=[dhcp-client item number] dist=[distance]
:global setDistDhcp do={
	:if ([/ip dhcp-client get number=$ifNum default-route-distance] != $dist) do={
		/ip dhcp-client set default-route-distance=$dist numbers=$ifNum
	}
}

# -----------------------------------------------
# Set default route distance in a static route
# ex. $setDistRoute gateway=[gateway ip address] dist=[distance]
:global setDistRoute do={
	/ip route set [/ip route find gateway=$gateway] distance=$dist
}


# -----------------------------------------------
# Add static route
# ex. $addRoute gateway=[gateway ip address] dst=[destinattion address]
:global addRoute do={
	:if ([/ip route find where dst-address="$dst/32"] = "") do={
		/ip route add dst-address="$dst/32" gateway=$gateway distance=1 comment="Temporary Route"
	}
}


# -----------------------------------------------
# Delete static route (delete all routes with the comment)
:global delRoute do={
	/ip route remove [/ip route find comment="Temporary Route"]
}


# -----------------------------------------------
# functions to enable/disable logs
:global infoLogOn do={ /system logging enable 0 }
:global infoLogOff do={ /system logging disable 0 }
:global warnLogMsg do={ /log warning message=$msg }
