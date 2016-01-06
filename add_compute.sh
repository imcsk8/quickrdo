#!/bin/sh -e

export LANG=en_US.utf8

if [[ -z $1 ]]; then
    echo "Usage: $0 <Compute node IP>"
    exit 0
fi

compute_ip=$1

echo
echo "Doing preparations..."
echo

# Temporarily accept all incoming packets and modify iptables config file.
iptables -I INPUT 1 -j ACCEPT
controller_ip=$(cat controller.txt | awk -F'=' '/CONFIG_CONTROLLER_HOST=/{print $2}')
sed -i "s/\(^-A INPUT -s \)$controller_ip\(\/.*\)/&\n\1$compute_ip\2/" /etc/sysconfig/iptables

ssh-copy-id root@${compute_ip}
scp ./lib/prep_compute.sh root@${compute_ip}:/root/
ssh root@${compute_ip} "/root/prep_compute.sh pre"

echo
echo "Installing RDO with packstack...."
echo

./lib/genanswer.sh compute $compute_ip

packstack --answer-file=compute.txt

ssh root@${compute_ip} "/root/prep_compute.sh post $compute_ip"

echo
echo "Done. Now, rebooting the server."
echo

ssh root@${compute_ip} reboot || :
