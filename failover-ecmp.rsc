# ------------------- header -------------------
# Script by Ricardo Franzen - rfranzen<at>gmail.com
# If you use this script, or edit and
# re-use it, please keep the header intact.
# ----------------------------------------------
# **********************************************
#                   IMPORTANT
# Default route must have the comment "_DEFAULT"
# **********************************************
# ------------------- header -------------------

# ------------- start editing here -------------
## Ping hosts
:local PingTargets { "192.203.230.10"; "198.97.190.53" }
#:local PingTargets { "38.230.3.46"; "192.0.43.22" }

## Route tables
:local routeTables { "from_guest"; "from_adm" };

## Gateways
:local gateways { "187.103.245.255"; "201.15.188.254" }

## Gateway proportion (in same order defined in gateway list above)
## use only if running in failover with load balancing mode
:global gatewaysProportion { "10"; "1" };

## loss limit (5 packages sent to each host)
:local LossLimit 3
# -------------- stop editing here --------------



# -------------------------- functions section begin --------------------------

## functions to enable/disable logs
##
:local infoLogOn do={ /system logging enable 0 };
:local infoLogOff do={ /system logging disable 0 };
:local infoLogMsg do={ /log info message=$msg };
:local warnLogMsg do={ /log warning message=$msg };
:local errirLogMsg do={ /log error message=$msg };

## functino to add static routes
##
:global addRoute do={
  :if ([/ip route find where dst-address="$destination/32"] = "") do={
    /ip route add dst-address="$destination/32" gateway=$gateway distance=1 comment=$comm
  }
}

## function to delete static routes created by script
##
:global delRoute do={
  /ip route remove [/ip route find comment=$comm]
}

## function to get gateways in loadbalancing ECMP mode
##
:global getGatewaysECMP do={
  :foreach i in=[/ip route find where routing-mark=$routetemp] do={
     :return [/ip route get $i gateway];
  }
}

# --------------------------- functions section end ---------------------------

## Tests
:local gwtemp 0
:local gwOffline 0
:local gwOnline 0

:foreach gwtemp in=$gateways do={
  :local cont 0
  :local routetemp 0
  :local desttemp 0
  :set $icmp 0

  ## temporary routes
  foreach desttemp in=$PingTargets do={
    $addRoute destination=$desttemp gateway=($gwtemp) comm="Temporary Route - failover script"
  }

  ## ping to targets
  :for cont from=1 to=5 do={
    foreach desttemp in=$PingTargets do={
      if ([/ping $desttemp count=1]=0) do={:set $icmp ($icmp + 1)}
      :delay 1
    }
  }

  ## if package loss <= limit, disable gateway; else enable gateway
  :if (($icmp <= $LossLimit)) do={
    :if (($gwOnline = 0)) do={
      :set gwOnline $gwtemp;
    } else {
      :set gwOnline ($gwOnline . "," . $gwtemp);
    }
  } else {
    :if (($gwOffline = 0)) do={
      :set gwOffline $gwtemp;
    } else {
      :set gwOffline ($gwOnline . "," . $gwtemp);
    }
  }

  ## delete temporary routes
  $delRoute comm="Temporary Route - failover script"

}

## se todos online, apaga rotas backup e habilita rotas default
:if (( $gwOffline = 0 )) do={
  $delRoute comm="_BACKUP"
  /ip route set [/ip route find comment="_DEFAULT"] disabled="no"
} else {
  :foreach routetemp in=$routeTables do={
    :local routegw [$getGatewaysECMP routetemp=$routetemp]
    :local newgwlist 0

    :for gw from=0 to=([:len $gateways]-1) step=1 do={
      :foreach gwOfftemp in=$gwOffline do={
        :if (( [:pick $gateways $gw] != $gwOfftemp )) do={
          ## aplica o multiplicador da proporcao
          :for prop from=0 to=([:pick $gatewaysProportion $gw]-1) step=1 do={
            :if (( $newgwlist = 0 )) do={
              :set newgwlist [:pick $gateways $gw]
            } else {
              :set newgwlist ($newgwlist . "," . [:pick $gateways $gw])
            }
          }
        }
      }
    }
    :local check [/ip route find routing-mark=$routetemp comment="_BACKUP"];
    :if (( [:len [$check]] = 0 )) do={
      /ip route add dst-address=0.0.0.0/0 routing-mark=($routetemp) distance=2 gateway=[:toarray $newgwlist] comment="_BACKUP"
    }
    /ip route set [/ip route find routing-mark=$routetemp comment="_DEFAULT"] disabled="yes"
  }
}

$infoLogMsg msg=("Gateways: Online - " . $gwOnline . " | Offline - " . $gwOffline)
