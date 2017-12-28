#! /bin/bash

OU='cn=Computers' # or something 'ou=Computers,ou=mydvision'

if [[ -n $1 ]]; then
  OU=$1
fi

echo "host ${hostfqdn} joining domain in OU ${OU} ..."

msktutil --create \
     --service host/$(hostname -s) \
     --service host/$(hostname -f) \
     --set-samba-secret \
     --enctypes 0x4 \
     --dont-expire-password \
     --description "Samba Server by msktutil" \
     --base "$OU"
