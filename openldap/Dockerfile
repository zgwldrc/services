FROM ubuntu
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y slapd ldap-utils ldapscripts iproute2 vim
ADD start.sh  /start.sh
CMD bash /start.sh
