#!/bin/bash

NAME=$1
OS=$2
RELEASE=$3
IP=$4

lxc-create -n ${NAME} -t ${OS} -- -R ${RELEASE}

echo "lxc.net.0.type = veth" >> /var/lib/lxc/${NAME}/config
echo "lxc.net.0.link = br0" >> /var/lib/lxc/${NAME}/config
echo "lxc.net.0.flags = up" >> /var/lib/lxc/${NAME}/config

echo "nameserver 8.8.8.8" > /var/lib/lxc/${NAME}/rootfs/etc/resolv.conf

cat <<EOF > /var/lib/lxc/${NAME}/rootfs/etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=static
IPADDR=${IP}
NETMASK=255.255.255.0
GATEWAY=172.16.32.1
ONBOOT=yes
HOSTNAME=${NAME}
NM_CONTROLLED=no
TYPE=Ethernet
MTU=
DHCP_HOSTNAME=hostname
EOF

lxc-start -n ${NAME}

#configure container for work, optional 
lxc-attach -n ${NAME} << EOF
yum update -y
yum install -y wget net-tools bash-completion bash-completion-extras vim mc
source /etc/profile.d/bash_completion.sh
EOF
