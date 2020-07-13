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
#  REQUIREMENTS:  env.vars file generated from 00-generate-cert.sh to configure InfluxDB, Grafana
#          BUGS:  ---
#         NOTES:  Not tested on RHEL, CentOS, Fedora
#        AUTHOR:  Shantanoo Desai, shantanoo.desai@gmail.com, des@biba.uni-bremen.de
#       COMPANY:  BIBA - Bremer Institut fuer Produktion und Logistik GmbH
#       VERSION:  0.4
#       CREATED:  07/07/20 14:06:48 CEST
#      REVISION:  ---
#===============================================================================

ROOT_UID=0
E_NOTROOT=85
SCRIPTSDIR=`pwd`
ENVFILE="env.vars"

function download_influxdb (distro) {

	case distro in
	"Debian"|"Ubuntu")
		echo -e "Downloading Debian Package for InfluxDB v1.8\n"
		wget --continue -P /tmp/influxdb/ "https://dl.influxdata.com/influxdb/releases/influxdb_1.8.0_amd64.deb"
		
		if [[ -f "/tmp/influxdb/influxdb_1.8.0_arm64.deb" ]]; then
			echo -e "Installing InfluxDB v1.8.0\n"
			dpkg -i /tmp/influxdb/influxdb_1.8.0_arm64.deb
		else
			echo -e "Error while downloading InfluxDB Debian Package\n"
			exit 3
		fi	
	;;

	"RHEL"|"CentOS"|"Fedora")
		echo -e "Downloading RPM Package for InfluxDB v1.8\n"
		wget --continue -P /tmp/influxdb/ "https://dl.influxdata.com/influxdb/releases/influxdb-1.8.0.x86_64.rpm"

		if [[ -f "/tmp/influxdb/influxdb-1.8.0.x86_64.rpm" ]]; then
			echo -e "Installing InfluxDB v1.8.0\n"
			yum localinstall /tmp/influxdb/influxdb-1.8.0.x86_64.rpm
		else
			echo -e "Error while downloading InfluxDB RPM Package\n"
			exit 3
		fi
	;;

	*)
		echo -e "Unknown Distribution. Please Install Manually.\n"
		exit 3
	;;

	esac    # --- end of case ---
}


function download_telegraf (distro) {

	case distro in
	"Debian"|"Ubuntu")
		echo -e "Downloading Debian Package for Telegraf v1.14-5.1\n"
		wget --continue -P /tmp/telegraf/ "https://dl.influxdata.com/telegraf/releases/telegraf_1.14.5-1_amd64.deb"
		
		if [[ -f "/tmp/telegraf/telegraf_1.14.5-1_amd64.deb" ]]; then
			echo -e "Installing Telegraf v1.14.5-1\n"
			dpkg -i /tmp/telegraf/telegraf_1.14.5-1_amd64.deb
		else
			echo -e "Error while downloading Telegraf Debian Package\n"
			exit 3
		fi	
	;;

	"RHEL"|"CentOS"|"Fedora")
		echo -e "Downloading RPM Package for Telegraf v1.14.5-1\n"
		wget --continue -P /tmp/telegraf/ "https://dl.influxdata.com/telegraf/releases/telegraf-1.14.5-1.x86_64.rpm"

		if [[ -f "/tmp/telegraf/telegraf-1.14.5-1.x86_64.rpm" ]]; then
			echo -e "Installing Telegraf v1.14.5-1\n"
			yum localinstall /tmp/telegraf/telegraf-1.14.5-1.x86_64.rpm
		else
			echo -e "Error while downloading Telegraf RPM Package\n"
			exit 3
		fi
	;;

	*)
		echo -e "Unknown Distribution. Please Install Manually.\n"
		exit 3
	;;

	esac    # --- end of case ---
}


function download_grafana (distro) {

	case distro in
	"Debian"|"Ubuntu")
		echo -e "Downloading Debian Package for Grafana v7.0.5\n"
		apt-get install -y adduser libfontconfig1
		wget --continue -P /tmp/grafana/ " https://dl.grafana.com/oss/release/grafana_7.0.5_amd64.deb"
		
		if [[ -f "/tmp/grafana/grafana_7.0.5_amd64.deb" ]]; then
			echo -e "Installing Grafana v7.0.5\n"
			dpkg -i /tmp/grafana/grafana_7.0.5_amd64.deb
		else
			echo -e "Error while downloading Grafana Debian Package\n"
			exit 3
		fi	
	;;

	"RHEL"|"CentOS"|"Fedora")
		echo -e "Downloading RPM Package for Grafana v7.0.5\n"
		wget --continue -P /tmp/grafana/ "https://dl.grafana.com/oss/release/grafana-7.0.5-1.x86_64.rpm"

		if [[ -f "/tmp/grafana/grafana-7.0.5-1.x86_64.rpm" ]]; then
			echo -e "Installing Grafana v7.0.5\n"
			yum install /tmp/grafana/grafana-7.0.5-1.x86_64.rpm
		else
			echo -e "Error while downloading Telegraf RPM Package\n"
			exit 3
		fi
	;;

	*)
		echo -e "Unknown Distribution. Please Install Manually.\n"
		exit 3
	;;

	esac    # --- end of case ---
}


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

#-------------------------------------------------------------------------------
#   STEP 3: Download Telegraf, InfluxDB, Grafana
#-------------------------------------------------------------------------------

download_influxdb($DISTRO) && download_telegraf($DISTRO) && download_grafana($DISTRO)

if [ $? -ne 0 ]; then
	echo -e "Error while downloading TIG stack\n"
	exit 4
fi

exit
