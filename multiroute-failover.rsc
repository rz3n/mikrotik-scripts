# ------------------- header -------------------
# Script by Ricardo Franzen - rfranzen<at>gmail.com
# If you use this script, or edit and
# re-use it, please keep the header intact.
# Description (in portuguese): https://www.rfranzen.com.br/2016/05/script-de-failover-redundancia-para.html
# Tested on: > routeros v6.36
# ------------------- header -------------------




# ------------- start editing here -------------
## Ping hosts
:local PingTargets { "192.203.230.10"; "198.97.190.53" }

## Route tables
:local routeTables { "route_guests"; "route_adm"; "route_mail1"; "route_mail2" }

## Gateways
:local gateways { "x.x.x.x"; "x.x.x.x" }

## loss limit (5 packages sent to each host)
:local LossLimit 3
# -------------- stop editing here --------------




## functions to enable/disable logs
##
:global infoLogOn do={ /system logging enable 0 }
:global infoLogOff do={ /system logging disable 0 }
:global warnLogMsg do={ /log warning message=$msg }

## function to sent email
##
:global sendEmail do={
	/tool e-mail send to=notify@yourmail.com subject="Mikrotik - Link Down" body=$msg
}

## function to enable/disable route tables
##
:global setRouteMark do={
	/ip route set [/ip route find gateway=$gw routing-mark=$mark] disabled=$disabled
}

## function to add static routes
##
:global addRoute do={
	:if ([/ip route find where dst-address="$destino/32"] = "") do={
		/ip route add dst-address="$destino/32" gateway=$gateway distance=1 comment="Temporary route - script failover"
	}
}

## function to delete static routes created by script
##
:global delRoute do={
	/ip route remove [/ip route find comment="Temporary route - script failover"]
}

## turn off info logs temporarily
$infoLogOff

## Tests
:local gwtemp 0

:foreach gwtemp in=$gateways do={
	:local cont 0
	:local routetemp 0
	:local desttemp 0
	:set $icmp 0

	## temporary routes
	foreach desttemp in=$PingTargets do={
		$addRoute destino=$desttemp gateway=($gwtemp)
	}

	## Ping to targets
	:for cont from=1 to=5 do={
		foreach desttemp in=$PingTargets do={
			if ([/ping $desttemp count=1]=0) do={:set $icmp ($icmp + 1)}
			:delay 1
		}
	}

	## if package loss <= limit, disable gateway; else enable gateway
	:if (($icmp <= $LossLimit)) do={
		:foreach routetemp in=$routeTables do={
			$setRouteMark gw=($gwtemp) mark=($routetemp) disabled="no"
		}
	} else {
		:foreach routetemp in=$routeTables do={
			$setRouteMark gw=($gwtemp) mark=($routetemp) disabled="yes"
			$warnLogMsg msg=("Gateway " . ($gwtemp) . " offline")
			#$sendEmail msg=("Gateway " . ($gwtemp) . " offline")
		}
	}

	## delete temporary routes
	$delRoute

}

## re-enable info logs
$infoLogOn
