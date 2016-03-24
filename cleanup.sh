#!/bin/sh

function cleanup_all {
    services=$(systemctl list-unit-files | grep -E "(redis|mariadb|openstack|neutron|rabbitmq-server).*\s+enabled" | cut -d" " -f1)
    for s in $services; do
        systemctl stop $s
        systemctl disable $s;
    done

    # Just remove running VM's
    for x in $(virsh list | grep instance- | awk '{print $2}'); do
        virsh destroy $x
        virsh undefine $x
    done

    yum remove -y "rabbitmq-server*" \
        "redis*" "*openstack*" "*neutron*" "*nova*" "*keystone*" \
        "*glance*" "*cinder*" "*heat*" "*ceilometer*" openvswitch \
        "*mariadb*" "*mongo*" "*memcache*" \
        "rdo-release-*"

    for x in nova glance cinder keystone horizon neutron heat ceilometer;do
        rm -rf /var/lib/$x /var/log/$x /etc/$x
    done

    rm -rf /root/.my.cnf /var/lib/mysql \
        /etc/openvswitch /var/log/openvswitch 

    if vgs cinder-volumes; then
        vgremove -f cinder-volumes
    fi

    for x in $(losetup -a | grep -v docker | sed -e 's/:.*//g'); do
        losetup -d $x
    done
}

# main

echo "This will completely uninstall all openstack-related components."
echo -n "Are you really sure? (yes/no) "
read answer
if [[ $answer == "yes" ]]; then
    # Show everything
    cleanup_all 
    echo "Finished. Reboot the server to refresh processes."
else
    echo "Cancelled."
fi

