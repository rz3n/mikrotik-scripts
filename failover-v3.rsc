# ------------------- header -------------------
# Script by Ricardo Franzen - rfranzen<at>gmail.com
# If you use this script, or edit and
# re-use it, please keep the header intact.
# Tested on: routeros >v6.44
# ------------------- header -------------------



# **********************************************
# ------------- start editing here -------------

## local gateways
:global failOverGateways {
  addr={"pppoe-out1";"192.168.5.1";"pppoe-out2"};
  stat={};
  last={};
}

## failover definitions
## set the domain with A records with IP's that will
## be used on tests
:global failOverListUrl "failover.yourdomain.com"

## Route tables
:global failOverRouteTables { "from_guest"; "from_adm" }

## loss limit (5 packages send to each host)
:global failOverLossLimit 3

## email alerts
:global failOverEmailNotify false
:global failOverEmailNotificationInterval 1800
:global failOverEmail "your@email.com"

## telegram alerts
:global failOverTelegramNotify false
:global failOverTelegramNotificationInterval 1800
:global failOverTelegramBotToken
:global failOverTelegramChatID

:local TelegramURL "https://api.telegram.org/bot$failOverTelegramBotToken/sendMessage?chat_id=$failOverTelegramChatID&parse_mode=Markdown&text="

# -------------- stop editing here --------------
# ***********************************************


## --------------------------------------------------------
## variables
:global failOverEmailLastNotification
:global failOverTelegramLastNotification
:global failOverTestIPs
:global OSversion [/system resource get version]
:global SystemName [/system identity get name]
:global SystemSerial [/system routerboard get serial-number]
:global updateRoutes false
:local failOverFwListName "failoverScript"
:local failOverRouteComment "## failover auto"


## --------------------------------------------------------
## [FUNCTION] check notification interval
:local checkInterval do={
  :local startTime [/system clock get time]

  :if ($startTime > $lastTime) do={
    # subtract startTime from endTime to get time elapsed
    :local finalTime ( $startTime - $lastTime );
  } else {
    :local finalTime "00:00:00"
  }

  # convert hours to seconds, add to sum
  :local sum ( $sum + ( [ :pick $finalTime 0 2 ] * 60 * 60 ));

  # convert minutes to seconds, add to sum
  :set sum ( $sum + ( [ :pick $finalTime 3 5 ] * 60 ));

  # add seconds to sum
  :set sum ( $sum + [ :pick $finalTime 6 8 ] );

  :if (($sum < $timeInterval)) do={
    return false
  } else {
    return true
  }
}

## --------------------------------------------------------
## [FUNCTION] send email
:local sendfailOverEmail do={
  /tool e-mail send to=$failOverEmail subject="Mikrotik - Link Down" body=$msg
}

## --------------------------------------------------------
## [FUNCTION] send telegram
:local sendTelegram do={
  /tool fetch keep-result=no url=($TelegramURL . $TelegramMessage)
}

## --------------------------------------------------------
## [FUNCTION] shortcut to logs
:local infoLogMsg do={ /log info message=$msg };
:local warnLogMsg do={ /log warning message=$msg };
:local errorLogMsg do={ /log error message=$msg };

## --------------------------------------------------------
## [FUNCTION] enable/disable route tables
:local setRouteMark do={
  :if ($disabled = "yes") do={ :set $disabled true }
  :if ($disabled = "no") do={ :set $disabled false }
  :if ([/ip route get [/ip route find gateway=$gw routing-mark=$mark] disabled] != $disabled) do={
    /ip route set [/ip route find gateway=$gw routing-mark=$mark] disabled=$disabled
  }
}

## --------------------------------------------------------
## [FUNCTION] check dns for failover test hosts
:local checkFailOverIPs do={
  :local resolveIPs
  :local testIP
  :local ack 0
  :local nack 0
  :global updateRoutes

  ## test if can resolve addresses
  :do {
    :resolve $foUrl server=1.1.1.1
    :set resolveIPs true
  } on-error={
    :set resolveIPs false
  }

  if ($resolveIPs) do={
    :do {
      ## check if current dns result matches with address list
      :foreach addr in=[/ip dns cache find where (name=$foUrl)] do={
        :set testIP [/ip dns cache get $addr address]
        if (([/ip firewall address-list print as-value where list=$fwAddrList address=$testIP]) != "") do={
          :set ack ($ack+1)
        } else {
          :set nack ($nack+1)
        }
      }

      ## if some address are different, delete and update
      :if ($nack != 0) do={
        /ip firewall address-list remove [/ip firewall address-list find where list=$fwAddrList]
        :foreach addr in=[/ip dns cache find where (name=$foUrl)] do={
          :set testIP [/ip dns cache get $addr address]
          /ip firewall address-list add list=$fwAddrList address=$testIP
        }
        :set updateRoutes true
      }

      return true
    } on-error={
      return false
    }

  } else {
   return false
  }
}

## --------------------------------------------------------
## [FUNCTION] get hosts from address-list
## $fwAddrList - address list where hosts used in failover are defined
:local getFailOverIPs do={
  :local cont 0
  :global failOverTestIPs

  :do {
    :foreach i in=[/ip firewall address-list find list=$fwAddrList] do={
      :set ($failOverTestIPs->"$cont") [/ip firewall address-list get $i address]

      :set cont ($cont +1)
    }
    return true
  } on-error={
    return false
  }
}

## --------------------------------------------------------
## [FUNCTION] compare static routes to hosts in address list
## $routeComment - default comment used for this script
## $fwAddrList   - address list where hosts used in failover are defined
:local checkRoute do={
  :local testAddr
  :global updateRoutes

  :foreach sDst in=[/ip route find comment=$routeComment] do={
    :set testAddr [/ip route get $sDst dst-address];
    :set testAddr [:pick $testAddr 0 [:find $testAddr "/"]];

    :if ([/ip firewall address-list find list=$fwAddrList address=$testAddr] = "") do={
      :set updateRoutes true
    }
  }
}

## --------------------------------------------------------
## [FUNCTION] add static routes
:local addRoute do={
  :if ([/ip route find dst-address="$destination/32"] = "") do={
    /ip route add dst-address="$destination/32" gateway=$gateway distance=1 comment=$failOverRouteComment
  } else={ /log error "destino: $destination gateway: $gateway" }
}

## --------------------------------------------------------
## [FUNCTION] delete static routes created by script
:local delRoute do={
  /ip route remove [/ip route find comment=$failOverRouteComment]
}


## --------------------------------------------------------
## --------------------------------------------------------
## check routes

## check and update failover address in address-list
$checkFailOverIPs foUrl=$failOverListUrl fwAddrList=$failOverFwListName
$checkRoute routeComment=$failOverRouteComment fwAddrList=$failOverFwListName



## check the number of static routes
:if ([:len [/ip route find comment="$failOverRouteComment"]] != ([:len ($failOverGateways->"addr")]*2)) do={
  set updateRoutes true
}

## if needed, update routes
:if ($updateRoutes) do={
  $getFailOverIPs fwAddrList=$failOverFwListName

  $delRoute failOverRouteComment=$failOverRouteComment

  :local dstCount 0
  :local gwCount 0

  ## creates two routes for each gateway
  :for gwCount from=0 to=([:len ($failOverGateways->"addr")]-1) do={
    $addRoute destination=($failOverTestIPs->"$dstCount") gateway=($failOverGateways->"addr"->"$gwCount") failOverRouteComment=$failOverRouteComment
    :set dstCount ($dstCount+1)
    $addRoute destination=($failOverTestIPs->"$dstCount") gateway=($failOverGateways->"addr"->"$gwCount") failOverRouteComment=$failOverRouteComment
    :set dstCount ($dstCount+1)
  }
}


## --------------------------------------------------------
## --------------------------------------------------------
## Tests
:local gwCount 0

:for gwCount from=0 to=([:len ($failOverGateways->"addr")]-1) do={
  :local cont 0
  :local desttemp 0
  :local routetemp 0
  :set $icmp 0

  ## get current destinations in route table
  :foreach i in=[/ip route find comment=$failOverRouteComment gateway=($failOverGateways->"addr"->"$gwCount")] do={
    ## ping to targets
    :for cont from=1 to=5 do={
      :local targetTest [/ip route get $i dst-address]
      :set targetTest [:pick $targetTest 0 [:find $targetTest "/" -1]];

      if ([/ping $targetTest count=1]=0) do={:set $icmp ($icmp + 1)}
      :delay 1
    }
  }

  ## if package loss <= limit, disable gateway; else enable gateway
  :if (($icmp <= $failOverLossLimit)) do={
    :foreach routetemp in=$failOverRouteTables do={
      $setRouteMark gw=($failOverGateways->"addr"->"$gwCount") mark=($routetemp) disabled="no"
    }
    :set ($failOverGateways->"stat"->"$gwCount") 1
  } else {
    :foreach routetemp in=$failOverRouteTables do={
      $setRouteMark gw=($failOverGateways->"addr"->"$gwCount") mark=($routetemp) disabled="yes"
    }
    :set ($failOverGateways->"stat"->"$gwCount") 0
    $errorLogMsg msg=("Gateway " . ($failOverGateways->"addr"->"$gwCount") . " offline")

    ## notifications
    :if (($failOverEmailNotify)) do={
      :if (([$checkInterval lastTime=$failOverEmailLastNotification timeInterval=$failOverEmailNotificationInterval])) do={
        $sendfailOverEmail failOverEmail=$failOverEmail msg=("Gateway " . ($failOverGateways->"addr"->"$gwCount") . " offline")
        :set failOverEmailLastNotification [/system clock get time]
      }
    }
    :if (($failOverTelegramNotify)) do={
      :if (([$checkInterval lastTime=$failOverTelegramLastNotification timeInterval=$failOverTelegramNotificationInterval])) do={
        $sendTelegram TelegramURL=$TelegramURL TelegramMessage=("System: $SystemName %0ARouterOS: $OSversion %0AGateway: " . $failOverGateways->"addr"->"$gwCount" . " is *offline*")
        :set failOverTelegramLastNotification [/system clock get time]
      }
    }
  }
}