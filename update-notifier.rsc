:local emailAddress "example@domain.com"
:local name [/system identity get name];

/system package update
check-for-updates

:if ([get installed-version] != [get latest-version]) do={
  :log info "Package update available. Sending email..."

  /ip address print file=address
  :local a [/file get address.txt contents]

  /tool e-mail send to="$emailAddress" subject="[Mikrotik][$name] - Update Available" body="New update available. \n\n $a"
}
