#!/bin/bash
set -e

setup(){
IFS=. component=(${DOMAIN:-example.com})
suffix=""
for c in ${component[@]}
do
suffix="$suffix,dc=$c"
suffix=${suffix#,}
done

component=($component)
organization=${component[0]}
rootDn=cn=admin,$suffix
rootPw=$(slappasswd -n -s "${ROOT_PW}")
olcSuffix=$suffix

# modify {1}mdb user database
cat <<-EOF | ldapmodify -Q -YEXTERNAL -H ldapi:/// 
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: ${olcSuffix}
-
replace: olcRootDN
olcRootDN: cn=admin,$olcSuffix
-
replace: olcRootPW
olcRootPW: ${rootPw}
EOF

cat <<-EOF | ldapadd -x -D cn=admin,$olcSuffix -w "${ROOT_PW}"
dn: $olcSuffix
objectclass: dcObject
objectclass: organization
o: $organization
dc: $organization

dn: cn=admin,$olcSuffix
objectclass: organizationalRole
cn: admin
EOF
touch /var/lib/ldap/setuped.flag
}

/etc/init.d/slapd start
if [ ! $? -eq 0 ];then
    echo slapd start failed...
    exit 1
fi

if [ ! -e /var/lib/ldap/setuped.flag ];then
  setup
fi

killslapd(){
  ps -o pid -u openldap |grep -v PID | xargs kill
  exit 0
}

trap "killslapd" 1 2 3 6 15


while sleep 60; do
  ps aux |grep slapd |grep -q -v grep
  PROCESS_1_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 ]; then
    echo "slapd processes has already exited."
    exit 1
  fi
done
