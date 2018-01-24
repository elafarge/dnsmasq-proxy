#!/bin/sh

default_nameservers=""
for nameserver in $DEFAULT_NAMESERVERS
do
  default_nameservers="${default_nameservers}server=${nameserver}\n"
done

specific_nameservers=""
for nameserver in $SPECIFIC_NAMESERVERS
do
  nameserver="$(echo "$nameserver" | sed 's/:/\\\//g')"
  specific_nameservers="${specific_nameservers}server=\\/${nameserver}\n"
done

sed -i 's/{{DEFAULT_NAMESERVERS}}/'"$default_nameservers"'/g' /etc/dnsmasq.conf
sed -i 's/{{SPECIFIC_NAMESERVERS}}/'"$specific_nameservers"'/g' /etc/dnsmasq.conf

exec "$@"
