#!/bin/bash
#
# config_ldap_auth.sh - Configure LDAP authentication for a server
#
#
yum -y remove sssd

OS_REQ="CentOS release 6"
LDAP_TEST_ACCNT=test.me

###################################
# LDAP SERVERS
###################################
# PROD LDAP (new net)
LDAP_SERVER=192.168.1.1,192.168.1.3
DC=exampledomain

ME=`hostname -s`

function check_root() {
if [[ $EUID -ne 0 ]]; then
   echo "You must be root...exiting!"
   exit 1
fi
}


function what_to_do() {
   read -p "Do you want to ADD or REMOVE LDAP authentication? [add/remove] " OPERATION
}


function confirm_ldap() {
   echo -n "Testing LDAP connectivity..."
   if getent passwd | grep ${LDAP_TEST_ACCNT} > /dev/null ; then
      echo "confirmed!"
   fi
} 


PREREQS="
 apr-util-ldap \
 compat-openldap \
 pam_ldap \
 python-ldap \
 openldap \
 nss-pam-ldapd \
 nscd
"

function provision_opts() {
AUTHCFG_OPTS="
 --enablepamaccess \
 --enableldap \
 --ldapserver=${LDAP_SERVER} \
 --enablemkhomedir \
 --enableldapauth \
 --ldapbasedn=dc=${DC},dc=com \
 --disablesssd \
 --disablesssdauth \
 --disablepamaccess \
 --enableshadow
"
}

function deprovision_opts() {
AUTHCFG_OPTS="
 --disablepamaccess \
 --disableldap \
 --ldapserver= \
 --disablemkhomedir \
 --disableldapauth \
 --ldapbasedn= \
 --enablerfc2307bis \
 --disablesssdauth \
 --enablepamaccess \
 --enableforcelegacy \
 --disablefingerprint \
"
}



###############################################################################
# DOIT
###############################################################################
if [[ ! ${LDAP_SERVER+x} ]]; then
   echo "The LDAP_SERVER variable is not set! Edit the script!"
   exit 1
fi

# Check OS version
#if ! grep "{$OS_REQ}" /etc/issue > /dev/null ; then
#   echo
#   echo "This script must be run on ${OS_REQ}...exiting!"
#   exit 1
#fi

check_root
what_to_do

case ${OPERATION} in
	add)
	   provision_opts
   	   echo "Installing prerequisite packages..."
   	   yum -y install ${PREREQS}
        ;;
        remove)
	   echo
	   echo "WARNING - Do not log out of the console before verifying root"
 	   echo "access, in case something goes wrong with PAM!!!"
	   echo
	   sleep 2
	   deprovision_opts
        ;;
        *)
	   echo
	   echo "Type 'add' or 'remove'...try again!"
	   what_to_do
        ;;
esac


# DEBUG
#echo ; echo ${AUTHCFG_OPTS} ; exit


echo ; echo "Running authconfig in '--test' mode first..."
sleep 2
authconfig ${AUTHCFG_OPTS} --test | grep server


echo ; echo
read -p "Confirm the server is correct above. then hit <ENTER> to commit or <CTRL-C> to exit. " GO
sleep 1
authconfig ${AUTHCFG_OPTS} --updateall
echo
echo
confirm_ldap
