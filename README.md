# About this repository
Scripts, tests and other stuff about mikrotik

## Contribute
Feel free to collaborate.
[t.me/rfranzen](https://t.me/rfranzen).

---

## scripts

**auto-upgrade-packages.rsc**: Simple script to auto-upgrade RouterOS packages

**auto-upgrade-routerboard.rsc**: Simple script to auto-upgrade Routerboard Firmware

**failover-ecmp**: Dynamic failover script similar to multiroute but using [ECMP](https://wiki.mikrotik.com/wiki/ECMP_load_balancing_with_masquerade)

**failover-multiroute.rsc**: Dynamic failover script described and discussed in this [reddit](post https://www.reddit.com/r/mikrotik/comments/51bdms/multiroute_failover_script/)

**failover_multi-gateway_static-routes.rsc**: Similar to ***failover-multiroute***. The script will create static routes to pre-defined destinations to use in tests.

**functions.rsc**: Generic (and not updated) functions.

**update-notifier.rsc**: Notify if there are updates available.


## To-do

* Fail Over script: Improve notifications by setting a minimum interval between messages.
