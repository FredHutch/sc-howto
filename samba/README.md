# A Samba File Server for your Posix FS integrated in Active Directory

## Introduction

### What we want
We would like seamless access to our Posix file systems for our
Windows and Mac desktop users. The desktop computers are joined to an AD domain
and should not require to enter a username / password to access the Posix file
systems via CFS.

### What we have (Prerequisites)

1. We already have a method of accessing our Posix file systems
(via NFS, Gluster, BeeGFS etc ) from Unix systems
* We have implemented a method for identity mapping (LDAP, NIS or local files)
with consistent values for uid, uidNumber and gidNumber between Active Directory
and our preferred identify mapping (IDMAP) approach, according to RFC2307
* the commands `getent group` and `getent passwd` return lists of groups and
gidNumber as well as users and uidNumber in a few seconds without crashing or
timing out.
* You have configured Kerberos authentication via /etc/krb5.conf
* Basic stuff: Your server is properly time synced and in the correct time zone
(e.g. ntpd; dpkg-reconfigure tzdata), the command `hostname -f` returns the FQDN,
 `hostname -s` returns the short hostname (aka computername).

If point 2 or 3 are not true for you today please look at implementing a simple
IDMAP service such as ad2openldap: https://pypi.python.org/pypi/ad2openldap .
There are more complex solutions available such as Centrify, SSSD or winbind but
you will not need them.

## Installation

This installation is currently only tested on Ubuntu 16.04. If you have not yet
installed the prerequisites please review the config files under ![/etc](./etc/)  

Login to a the system you wan to install Samba on, switch to the root user,
install Samba and copy the config from this repository:

    sudo su -
    apt update; apt install -y wget samba libsasl2-modules-gssapi-mit msktutil
    mv /etc/samba/smb.conf /etc/samba/smb.conf.orig
    wget https://raw.githubusercontent.com/FredHutch/sc-howto/master/samba/etc/samba/smb.conf -O /etc/samba/smb.conf    

## Configuration

Replace the REALM string MYDOM.ORG and domain MYDOM in smb.conf with your own
settings

    sed -i 's/MYDOM.ORG/YOURREALM.COM/' /etc/samba/smb.conf
    sed -i 's/MYDOM/YOURDOM/' /etc/samba/smb.conf

replace the default /scratch folder with something simple that already exists
such as /tmp

    sed -i 's/\/scratch/\/tmp/' /etc/samba/smb.conf

as root use kinit to get a kerberos ticket for the domain account that has
permissions to join computers to the domain and confirm with klist that there is
a kerberos ticket.

    kinit johndoe
      Password for johndoe@YOURREALM.COM:
    klist
      Ticket cache: FILE:/tmp/krb5cc_0
      Default principal: johndoe@YOURREALM.COM

    Valid starting     Expires            Service principal
    12/26/17 12:31:33  12/26/17 22:31:25  krbtgt/YOURREALM.COM@YOURREALM.COM
    	renew until 01/02/18 12:31:25

join the computer to the domain and restart the samba services

    computername=$(hostname -s)
    hostfqdn=$(hostname -f)

    msktutil --dont-expire-password --no-pac --computer-name $computername --enctypes 0x07 -k /etc/krb5.keytab -h $hostfqdn -s host/$hostfqdn -s HOST/$computername --upn host/$hostfqdn --description "Kerberos Account for SAMBA by msktutil" --set-samba-secret -b 'ou=Servers,ou=Computers,ou=SciComp' --server dc

    systemctl restart smbd nmbd

check log output to verify that samba is up and running

     tail /var/log/samba/log.smbd

and you want to see something like this, otherwise continue with troubleshooting

    [2017/12/26 15:25:29.976673,  0] ../lib/util/become_daemon.c:124(daemon_ready)
    STATUS=daemon 'smbd' finished starting up and ready to serve connections
    [2017/12/26 15:25:29.976865,  2] ../source3/smbd/server.c:1009(smbd_parent_loop)
    waiting for connections


## Troubleshooting

In some cases you cannot join the domain, there are several options

Pre-create the computer account in a Windows Tool called **Active Directory Users
and Computers** . After that try joining

![Active Directory Users and Computers](assets/markdown-img-paste-20171226134251669.png)


If joining the domain using msktutil doe snot work please try the legacy method

    net ads join -k
    net ads keytab add -k
