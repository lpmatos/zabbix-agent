#!/bin/bash
set -ex
cd /tmp

ZabbixServer=172.31.21.35
ServersName=$(hostname)
ZabbixConfig="/etc/zabbix/zabbix_agentd.conf"

DELETE=${1}

if [[ "delete" = ${DELETE} ]]; then
	apt-get remove zabbix-agent -y
	apt-get autoremove
	echo "zabbix-agent deleted"
	exit 1
fi

sudo wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+$(lsb_release -sc)_all.deb
sudo dpkg -i zabbix-release_5.0-1+$(lsb_release -sc)_all.deb
sudo apt update
sudo apt -y install zabbix-agent
touch ${ZabbixConfig}

sed -i \
	-e 's/^.*StartAgents=.*$/StartAgents=0/' \
	-e 's/^Server=.*$/Server='${ZabbixServer}'/' \
	-e 's/^ServerActive=.*$/ServerActive='${ZabbixServer}'/' \
	-e 's/^Hostname=.*$/Hostname='${ServersName}'/' \
	${ZabbixConfig}

sudo systemctl enable zabbix-agent 
sudo systemctl start zabbix-agent 
sudo systemctl status zabbix-agent
