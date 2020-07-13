#!/bin/bash
#===============================================================================
#
#          FILE:  00-generate-cert.sh
# 
#         USAGE:  ./00-generate-cert.sh 
# 
#   DESCRIPTION:  Script to generate a standalone certificate using certbot
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  <DOMAIN_NAME> as String for registration, <EMAIL> as String for registration
#          BUGS:  ---
#         NOTES:  Not tested on CentOS, RHEL, Fedora.
#        AUTHOR:  Shantanoo Desai, shantanoo.desai@gmail.com, des@biba.uni-bremen.de
#       COMPANY:  BIBA - Bremer Institut fuer Produktion und Logistik GmbH
#       VERSION:  0.2
#       CREATED:  07/07/20 10:57:32 CEST
#      REVISION:  ---
#===============================================================================

ROOT_UID=0
E_NOTROOT=87
ENVFILE="env.vars"

#===  FUNCTION  ================================================================
#          NAME:  determine_distro
#   DESCRIPTION:  determine which type of Linux Distribution the machine is
#    PARAMETERS:  none
#       RETURNS:  distribution name
#===============================================================================

function determine_distro ()
{
	if grep -Eqii "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
		DISTRO="CentOS"
	
	elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release ; then
		DISTRO="RHEL"
	
	elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release ; then
		DISTRO="Fedora"

	elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release ; then
		DISTRO="Debian"

	elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release ; then
		DISTRO="Ubuntu"

	else
		DISTRO=$(uname -s)

	fi
}    # ----------  end of function determine_distro  ----------



#===  FUNCTION  ================================================================
#          NAME:  install_certbot
#   DESCRIPTION:  install certbot binary on machine based on machine's distribution
#    PARAMETERS:  none
#       RETURNS:  none
#===============================================================================

function install_certbot ()
{
	
	echo "#-------------------------------------------------------------------------------"
	echo "#  STEP 2: Installing certbot on the machine "
	echo "#-------------------------------------------------------------------------------"
	
	
	determine_distro

	case $DISTRO in

	"CentOS"|"RHEL")
		echo -e "Using yum to install certbot on ${DISTRO} \n"
		echo -e "Enabling Extra Packages for Enterprise Linux (EPEL)\n"
		
		yum --enablerepo=extras install epel-release
		yum install certbot

		retval=$?

		if [ $retval -ne 0 ]; then
			echo -e "Error while installing certbot on machine \n"
			exit $retval
		fi
	;;

	"Fedora")
		echo -e "Using dnf to install certbot on ${DISTRO}\n"
		dnf install certbot
	;;

	"Debian")
		echo -e "Using apt-get to install certbot on ${DISTRO} \n"

		apt-get install certbot

		retval=$?

		if [ $retval -ne 0 ]; then
			echo -e "Error while installing certbot on machine \n"
			exit $retval
		fi
	;;

	"Ubuntu")

		source /etc/*-release

		echo -e "Distribution Version: $DISTRIB_RELEASE\n"

		case $DISTRIB_RELEASE in
			"19.04"|"20.04")
				apt-get update
				apt-get install -y software-properties-common
				add-apt-repository universe
				apt-get update
			;;

			"18.04"|"16.04")
				apt-get update
				apt-get install -y software-properties-common
				add-apt-repository universe
				add-apt-repository ppa:certbot/certbot
				apt-get update
			;;

			*)
				echo -e "Check Certbot official docs for manual installation on this version.\n"
			;;
		esac

		echo -e "Installing Certbot\n"
		apt-get install certbot

		retval=$?

		if [ $retval -ne 0 ]; then
			echo -e "Error while installing certbot on machine\n"
			exit $retval
		fi
	;;
	
	*)
		echo -e "Unknown Distribution. Please install certbot manually\n"
		exit 1
	;;

	esac    # --- end of case ---

}    # ----------  end of function install_certbot  ----------



#-------------------------------------------------------------------------------
#   Check if Script is running with Root Privileges
#-------------------------------------------------------------------------------


if [ "$UID" -ne "$ROOT_UID" ]; then
	echo -e "Must be Root to run this script\n"
	exit $E_NOTROOT
fi


#-------------------------------------------------------------------------------
#   Check for number of input parameters with script
#-------------------------------------------------------------------------------

if [ $# -lt 2 ]; then
	echo -e "\n USAGE: `basename $0` <DOMAIN_NAME> <EMAIL>"
	exit 1
else
	DOMAIN=$1
	EMAIL=$2
	echo -e "CERTBOT_DOMAIN=$DOMAIN" >> $ENVFILE
	echo -e "CERTBOT_EMAIL=$EMAIL" >> $ENVFILE
fi


echo "#-------------------------------------------------------------------------------"
echo "#   Setting Certificates for Domain Name: ${DOMAIN}"
echo "#   E-mail Address for registration: ${EMAIL}"
echo "#-------------------------------------------------------------------------------"


echo "#-------------------------------------------------------------------------------"
echo "#   STEP 1: Checking if certbot exists on machine"
echo "#-------------------------------------------------------------------------------"

if ! command -v certbot &> /dev/null; then
	echo -e "certbot not installed on machine\n"
	install_certbot_auto
else
	echo -e "certbot already exists on machine\n"
	echo -e "skipping STEP:2 Installing certbot\n"
fi



echo "#-------------------------------------------------------------------------------"
echo "#   STEP 3: Enabling HTTP Port (80) via Firewall "
echo "#-------------------------------------------------------------------------------"

determine_distro

echo -e "DISTRO=$DISTRO" >> $ENVFILE

echo "Enabling HTTP port for certbot on ${DISTRO}"


case $DISTRO in
	"Raspbian"|"Debian"|"Ubuntu")
		if ! command -v ufw &> /dev/null; then
			echo -e "no ufw installed on machine\n"
			echo -e "installing ufw\n"
			apt install ufw
		fi

		echo -e "enabling HTTP port on Machine\n"
		ufw allow 80
	;;
		

	"CentOS"|"RHEL"|"Fedora")
		if ! command -v firewall-cmd &> /dev/null; then
			echo -e "no firewall-cmd installed on machine\n"
			echo -e "installing firewall-cmd\n"
			yum install firewall-cmd
		fi
		
		echo -e "enabling HTTP port on machine\n"
		firewall-cmd --add-service=http
		firewall-cmd --runtime-to-permanent
	;;

	*)
		echo -e "Unknown Distribution. Please enable HTTP Port manually\n"
		exit 2
	;;

esac    # --- end of case ---



echo "#-------------------------------------------------------------------------------"
echo "#   STEP 4: Generating SSL Certificates for the Machine using certbot"
echo "#-------------------------------------------------------------------------------"

certbot certonly \
	--standalone \
	--preferred-challenges http \
	--agree-tos \
	-m $EMAIL \
	-d $DOMAIN

cert_return=$?

if [ $cert_return -ne 0 ]; then
	echo -e "certbot threw errors while generating certificates\n"
	exit $cert_return
fi


#-------------------------------------------------------------------------------
#   Check if Directory for generated certificates exists and files exist within it
#-------------------------------------------------------------------------------

CERTDIR=/etc/letsencrypt/live/$DOMAIN

echo -e "Certificate Directory: $CERTDIR\n"

if [ -d $CERTDIR ]; then
	echo -e "Domain directory in letsencrypt directory exists\n"
	echo -e "Checking for certificates in the directory\n"

	if [[ -f $CERTDIR/fullchain.pem ]] && [[ -f $CERTDIR/privkey.pem ]]; then
		echo -e "Necessary certificates for SSL/HTTPS exist\n"
	else
		echo -e "No Certificates exist. Please check certbot logs\n"
		exit 3
	fi
else
	echo -e "No domain directory exists. Please check certbot logs\n"
	exit 3
fi


#-------------------------------------------------------------------------------
#   Adding Relevant files and Paths to Environment Variable Files
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#   INFLUXDB ENVIRONMENT VARIABLES FOR HTTPS
#-------------------------------------------------------------------------------
echo -e "# InfluxDB Environment Variables" >> $ENVFILE
echo -e "INFLUXDB_HTTP_HTTPS_ENABLED=true" >> $ENVFILE
echo -e "INFLUXDB_HTTP_HTTPS_CERTIFICATE=$CERTDIR/fullchain.pem" >> $ENVFILE
echo -e "INFLUXDB_HTTP_HTTPS_PRIVATE_KEY=$CERTDIR/privkey.pem" >> $ENVFILE



#-------------------------------------------------------------------------------
#   GRAFANA ENVIRONMENT VARIABLES FOR HTTPS
#-------------------------------------------------------------------------------
echo -e "# Grafana Server Environment Variables" >> $ENVFILE
echo -e "GF_SERVER_PROTOCOL=https" >> $ENVFILE
echo -e "GF_SERVER_HTTP_PORT=443" >> $ENVFILE
echo -e "GF_SERVER_DOMAIN=$DOMAIN" >> $ENVFILE
echo -e "GF_SERVER_ROOT_URL=https://$DOMAIN" >> $ENVFILE
echo -e "GF_SERVER_CERT_FILE=$CERTDIR/fullchain.pem" >> $ENVFILE
echo -e "GF_SERVER_CERT_KEY=$CERTDIR/privkey.pem" >> $ENVFILE

echo -e "All necessary Environment Variables Written in: $ENVFILE \n"

exit 0
