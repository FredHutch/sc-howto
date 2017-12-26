#! /bin/bash

hostfqdn=$(hostname -f)
computername=$(hostname -s)
OU='ou=Computers' # or something 'ou=Computers,ou=mydvision'

if [[ "$hostfqdn" == "$computername" ]]; then
  echo "hostname -f and hostname -s return the same value, error in /etc/hosts"
  exit
fi

echo "host ${hostfqdn} joining domain in OU ${OU} ..."

msktutil --dont-expire-password --no-pac --computer-name $computername \
         --server dc --enctypes 0x07 -b "$OU" -k /etc/krb5.keytab -h $hostfqdn \
         -s host/$hostfqdn -s HOST/$computername --upn host/$hostfqdn  \
         --description "Kerberos Account for SAMBA by msktutil" --set-samba-secret
