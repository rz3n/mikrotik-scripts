:local emailAddress "example@domain.com"
:local name [/system identity get name];

/system package update
check-for-updates

:if ([get installed-version] != [get latest-version]) do={
  :log info "Package update available. Sending email..."

  /tool e-mail send to="$emailAddress" subject="[Mikrotik][$name] - Update Available" body="New update available."
}
