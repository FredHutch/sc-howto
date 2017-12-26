#! /bin/bash

hostfqdn=$(hostname -f)
computername=$(hostname -s)
OU='ou=Servers,ou=Computers,ou=SciComp'

if [[ "$hostfqdn" == "$computername" ]]; then 
  echo "hostname -f and hostname -s return the same value, error in /etc/hosts"
  exit
fi

msktutil.1404 --dont-expire-password --no-pac --computer-name $computername --server dc --enctypes 0x07 -b "$OU" -k /etc/krb5.keytab -h $hostfqdn -s host/$hostfqdn -s HOST/$computername --upn host/$hostfqdn  --description "Kerberos Account by msktutil" --set-samba-secret

