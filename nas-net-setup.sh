#!/bin/bash

## CCC - 12/15/16
## This script takes in user subnet port and hostname, and changes needed scripts
## So networking works in CentOS 6

## VARIABLES

persist="/etc/udev/rules.d/70-persistent-net.rules.bkp"
ifcfg="/etc/sysconfig/network-scripts/ifcfg-eth0"
exports="/etc/exports"
hostfile="/etc/hosts"
network="/etc/sysconfig/network"
counter=0

## Makes sure user is root

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

## Hostname validation

echo "Please enter the hostname for this server and press [ENTER]:"

read hostname

while [ $counter -lt 1 ] 
do
	if [ ! -z $hostname ] ; then

		echo "Is this $hostname correct?(y/n)"
		read input

		if [ $input == "y" ] ; then
			echo $counter
			let counter+=1
			echo $counter
		else
			echo "Please enter the hostname for this server and press [ENTER]:"
			read hostname;
		fi	
	else
		read hostname;
	fi
done

## Subnet input and validation

echo "Please enter the subnet this device is on (just the X part of 193.168.X.1) and press [ENTER]:"

read subnet

if [ $subnet -lt 256 ] && [ $subnet -gt 0 ] ; then 
	: 
else
	echo "Input is not valid, script is exiting";
	exit 1 ; 
fi

echo "Subnet is 192.168."$subnet".0"

## Moves rules file to allow networking after reboot

echo "Checking for network rules file, which prevents the cloned server from working"

if [ -f $persist ]; then 
	echo "Rules Will be moved to $persist.bkp"; 
	mv $persist $persist.bkp;
else
	echo "Network rule file not found"
fi

## Change networking on /etc/sysconfig/network-scripts/ifcfg-eth0

echo "Moving /etc/sysconfig/network-scripts/ifcfg-eth0 to ifcfg-eth0.bkp"

mv $ifcfg $ifcfg.bkp

echo "Creating new script at "$ifcfg""

## Code below generates the ifcfg file

cat <<EOF > $ifcfg
## File created via script. `date -I`
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
IPADDR=192.168.$subnet.51
PREFIX=24
GATEWAY=192.168.$subnet.1
DNS1=192.168.0.26
DOMAIN=192.168.$subnet.1
DEFROUTE=yes
IPV4_FAILURE_FATAL=yes
IPV6INIT=no
NAME="System eth0"
EOF

echo "$ifcfg has been installed"

## Change exports for the correct subnet

echo "Moving $exports to $exports.bkp"

mv $exports $exports.bkp

echo "Creating new script at $exports"

cat <<EOF > $exports
## File created via script. `date -I`
/xsinas-files 192.168.$subnet.0/24(rw,sync,no_root_squash,no_subtree_check,fsid=0)
EOF

echo "$exports has been installed."

## HOSTS

echo "Moving $hostfile to $hostfile.bkp"

mv $hostfile $hostfile.bkp

echo "Creating new script at $hostfile"

cat <<EOF > $hostfile
## File created via script. `date -I`
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
127.0.0.1 $hostname
EOF

echo "$hostfile has been installed."

## Edit /etc/sysconfig/network

echo "Moving $network to $network.bkp"

mv $network $network.bkp

echo "Creating new script at $network"

cat <<EOF > $network
## File created via script. `date -I`
NETWORKING=yes
HOSTNAME=$hostname
GATEWAY=192.168.$subnet.1
EOF

echo "$network has been installed."

echo "Script has completed successfully"

echo "Please reboot for changes to take effect"

exit 1
