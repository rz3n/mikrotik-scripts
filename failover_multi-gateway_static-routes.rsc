# ------------------- header -------------------
# Script by Ricardo Franzen - rfranzen<at>gmail.com
# If you use this script, or edit and
# re-use it, please keep the header intact.
# Tested on: routeros >v6.40
# ------------------- header -------------------



# ------------- start editing here -------------
## Gateways and remote destinatinos to test
:local gateways {
  "gw1"="192.168.1.1";
  "gw1-dst1"="8.8.8.8";
  "gw1-dst2"="1.1.1.1";
  "gw2"="192.168.2.1";
  "gw2-dst1"="208.67.222.222";
  "gw2-dst2"="1.0.0.1"
}


## Route tables
:local routeTables { "from_guest"; "from_adm" }

## loss limit (5 packages sent to each host)
:local LossLimit 3

## email alerts
:local email "your@email.com"
# -------------- stop editing here --------------


## --------------------------------------------------------
## variables
:local routeComment "## failover auto"
:global failoverCount


## --------------------------------------------------------
## function to sent email
:local sendEmail do={
  /tool e-mail send to=$email subject="Mikrotik - Link Down" body=$msg
}

## functions to enable/disable logs
##
:local infoLogMsg do={ /log info message=$msg };
:local warnLogMsg do={ /log warning message=$msg };
:local errorLogMsg do={ /log error message=$msg };

## --------------------------------------------------------
## function to enable/disable route tables
:local setRouteMark do={
  :if ($disabled = "yes") do={ :set $disabled true }
  :if ($disabled = "no") do={ :set $disabled false }
  :if ([/ip route get [/ip route find gateway=$gw routing-mark=$mark] disabled] != $disabled) do={
    /ip route set [/ip route find gateway=$gw routing-mark=$mark] disabled=$disabled
  }
}

## --------------------------------------------------------
## function to add static routes
:local addRoute do={
  :if ([/ip route find dst-address="$destination/32"] = "") do={
    /ip route add dst-address="$destination/32" gateway=$gateway distance=1 comment=$routeComment
  } else={ /log error "destino: $destination gateway: $gateway" }
}

## function to delete static routes created by script
##
:local delRoute do={
  /ip route remove [/ip route find comment=$routeComment]
}


## --------------------------------------------------------
## check routes

## if the number of static routes isn't correct delete all routes
:if ([:len [/ip route find comment="$routeComment"]] != (([:len $gateways]/3)*2)) do={
  $delRoute routeComment=$routeComment

  :local dst1Tmp 0
  :local dst2Tmp 0
  :local gwCount 0
  :local gwTmp 0

  ## creates two random routes for each gateway
  :for gwCount from=1 to=([:len $gateways]/3) do={
    :set gwTmp ("gw" . $gwCount)
    :set dst1Tmp ("gw" . $gwCount . "-dst1")
    :set dst2Tmp ("gw" . $gwCount . "-dst2")

    $addRoute destination=($gateways->"$dst1Tmp") gateway=($gateways->"$gwTmp") routeComment=$routeComment
    $addRoute destination=($gateways->"$dst2Tmp") gateway=($gateways->"$gwTmp") routeComment=$routeComment
  }
}



## --------------------------------------------------------
## Tests
:local gwCount 0

:for gwCount from=1 to=([:len $gateways]/3) do={
  :local cont 0
  :local desttemp 0
  :local gwTmp 0
  :local routetemp 0
  :set $icmp 0
  :set gwTmp ("gw" . $gwCount)

  ## ping to targets
  :for cont from=1 to=5 do={
    ## get current destinations in route table
    :foreach i in=[/ip route find comment=$routeComment gateway=($gateways->"$gwTmp")] do={
      :local targetTest [/ip route get $i dst-address]
      :set targetTest [:pick $targetTest 0 [:find $targetTest "/" -1]];

      if ([/ping $targetTest count=1]=0) do={:set $icmp ($icmp + 1)}
      :delay 1
    }
  }

  ## if package loss <= limit, disable gateway; else enable gateway
  :if (($icmp <= $LossLimit)) do={
    :foreach routetemp in=$routeTables do={
      $setRouteMark gw=($gateways->"$gwTmp") mark=($routetemp) disabled="no"
    }
  } else {
    :foreach routetemp in=$routeTables do={
      $setRouteMark gw=($gateways->"$gwTmp") mark=($routetemp) disabled="yes"
    }
    $errorLogMsg msg=("Gateway " . ($gateways->"$gwTmp") . " offline")
    #$sendEmail msg=("Gateway " . ($gwCount) . " offline")
  }
}

