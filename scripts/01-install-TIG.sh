#!/bin/bash
#===============================================================================
#
#          FILE:  01-install-TIG.sh
# 
#         USAGE:  ./01-install-TIG.sh 
# 
#   DESCRIPTION:  Bash Script to install Telegraf/InfluxDB/Grafana Latest Stable version on a machine
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  env.vars file generated from 00-generate-cert.sh to configure InfluxDB
#          BUGS:  ---
#         NOTES:  Not tested on RHEL, CentOS, Fedora
#        AUTHOR:  Shantanoo Desai, shantanoo.desai@gmail.com, des@biba.uni-bremen.de
#       COMPANY:  BIBA - Bremer Institut fuer Produktion und Logistik GmbH
#       VERSION:  0.3
#       CREATED:  07/07/20 14:06:48 CEST
#      REVISION:  ---
#===============================================================================

ROOT_UID=0
E_NOTROOT=85
SCRIPTSDIR=`pwd`
ENVFILE="env.vars"

#-------------------------------------------------------------------------------
#   STEP 1: Check if Script is running with Root Privileges
#-------------------------------------------------------------------------------

if [ "$UID" -ne "$ROOT_UID" ]; then
	echo -e "Must be Root to run this script\n"
	exit $E_NOTROOT
fi


#-------------------------------------------------------------------------------
#   STEP 2: Check for Environment Variables file: env.vars in present directory
#-------------------------------------------------------------------------------

if [[ ! -f $SCRIPTSDIR/env.vars ]]; then
	echo -e "Could not find the env.vars file.\n"
	echo -e "Please run the 00-generate-cert.sh script first.\n"
	exit 1
else
	echo -e "Found the env.vars environment variables file\n"
fi

# source the environment variables
eval `cat $ENVFILE`

echo -e " Found Distribution: $DISTRO\n"


case $DISTRO in
	"Debian"|"Raspbian")
		echo -e "Add InfluxData Repository to Sources List\n"
		wget -qO - https://repos.influxdata.com/influxdb.key | apt-key add -
		source /etc/os-release
		echo "deb https://repos.influxdata.com/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/influxdb.list

		echo -e "Add Grafana Repository to Sources List\n"
		wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -

		echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list 

		retval=$?
		if [ $retval -ne 0 ]; then
			echo -e "Unable to add the Telegraf/InfluxData/Grafana Repository in Sources List\n"
			exit $retval
		else
			echo -e "Installing Telegraf, InfluxDB and Grafana\n"
			apt-get update && apt-get install telegraf && apt-get install influxdb && apt-get install grafana
		fi
	;;

	"Ubuntu")
		echo -e "Add InfluxData Repository to Sources List\n"
		wget -qO - https://repos.influxdata.com/influxdb.key | apt-key add -
		source /etc/lsb-release
		echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | tee /etc/apt/sources.list.d/influxdb.list

		echo -e "Add Grafana Repository to Sources List\n"
		wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -

		add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"

		retval=$?
		if [ $retval -ne 0 ]; then
			echo -e "Unable to add the InfluxData Repository in Sources List\n"
			exit $retval
		else
			echo -e "Installing Telegraf, InfluxDB and Grafana\n"
			apt-get update && apt-get install telegraf && apt-get install influxdb && apt-get install grafana
		fi
	;;

	"RHEL"|"CentOS"|"Fedora")
		#WARNING: This section is not tested at all. The script might fail here!

		echo -e "Adding InfluxData Repository to yum Repos\n"
		cat <<- EOF > tee /etc/yum.repos.d/influxdb.repo
		[influxdb]
		name = InfluxDB - RHEL \$releasever
		baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
		gpgcheck = 1
		enabled = 1
		gpgkey = https://repos.influxdata.com/influxdb.key
		EOF

		echo -e "Adding Grafana Repository to yum Repos\n"
		cat <<-EOF > tee /etc/yum.repos.d/grafana.repo
		[grafana]
		name=grafana
		baseurl=https://packages.grafana.com/oss/rpm
		repo_gpgcheck=1
		enabled=1
		gpgcheck=1
		gpgkey=https://packages.grafana.com/gpg.key
		sslverify=1
		sslcacert=/etc/pki/tls/certs/ca-bundle.crt
		EOF

		retval=$?
		if [ $retval -ne 0 ]; then
			echo -e "Unable to add Telegraf/InfluxData/Grafana Repository in Sources List\n"
			exit $retval
		else
			yum install telegraf && yum install influxdb && yum install grafana
		fi
	;;

	*)
		echo -e "Unknown Distribution. Please Install Manually.\n"
		exit 2
	;;

esac    # --- end of case ---

exit
