# About this repository
Scripts, tests and other stuff about mikrotik

## Contribute
Feel free to collaborate.
[t.me/rfranzen](https://t.me/rfranzen).

---

## scripts

### auto-upgrade-packages.rsc
Simple script to auto-upgrade RouterOS packages


### auto-upgrade-routerboard.rsc
Simple script to auto-upgrade Routerboard Firmware


### failover-ecmp
Dynamic failover script similar to multiroute but using [ECMP](https://wiki.mikrotik.com/wiki/ECMP_load_balancing_with_masquerade)


### failover-v1.rsc
**Outdated script. I don't use it anymore**
Dynamic failover script described and discussed in this [reddit](post https://www.reddit.com/r/mikrotik/comments/51bdms/multiroute_failover_script/)


### failover-v2.rsc
Similar to ***failover-v1***. The script will create static routes to pre-defined destinations to use in tests.

It's very customizable. You can set notifications using Email and/or Telegram.


### failover-v3.rsc
Evolution of v2. Hosts used on tests are dynamically updated from a domain where are defined A records with the IP's that will be used on tests.


### functions.rsc
Generic (and not updated) functions.


### update-notifier.rsc
Notify if there are updates available.


## To-do
* Improve this documentation
