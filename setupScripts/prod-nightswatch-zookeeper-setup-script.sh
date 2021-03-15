#!/bin/bash
#setup infra-cli and default srcs.list
echo "deb http://10.47.4.220/repos/infra-cli/3 /" > /etc/apt/sources.list.d/infra-cli-svc.list
echo "deb http://10.47.4.220:80/repos/alertz-stretch-nagios-prod/7 /" >> /etc/apt/sources.list.d/infra-cli-svc.list

apt-get update
apt-get install --yes --allow-unauthenticated infra-cli

#setup your package
reposervice --host "10.24.0.41" --port 8080 env --version 7 --name zookeeperbuilder --appkey dummy| sudo tee /etc/apt/sources.list.d/zookeeper.list
apt-get update --allow-unauthenticated

echo "fk-auto-zoo fk-auto-zoo/bucket_name string prod-nightswatch-zk" | sudo -E debconf-set-selections

if [ -b /dev/vdb ]
then
    echo "Found additional device for /dev/vdb"
    mkfs.ext4 /dev/vdb
    mkdir -p /grid/1
    mount /dev/vdb /grid/1
    echo -e "\n/dev/vdb\t/grid/1\text4\terrors=remount-ro\t0\t2" >> /etc/fstab
fi

apt-get install --yes --allow-unauthenticated fk-cdh-repo
apt-get install --yes --allow-unauthenticated fk-ops-hosts-populator
apt-get install --yes --allow-unauthenticated fk-config-service-confd
apt-get install --yes --allow-unauthenticated oracle-j2sdk1.8
apt-get install --yes --allow-unauthenticated --allow-downgrades zookeeper=3.4.5+26-1.cdh4.7.0.p0.17~squeeze-cdh4.7.0
apt-get install --yes --allow-unauthenticated cosmos-zookeeper
apt-get install --yes --allow-unauthenticated fk-auto-zoo
apt-get install --yes --allow-unauthenticated python
apt-get install --yes --allow-unauthenticated cosmos-base cosmos-jmx cosmos-collectd stream-relay fk-rsyslog fk-libestr fk-liblognorm
apt-get install --yes --allow-unauthenticated netcat

/etc/init.d/fk-config-service-confd restart
systemctl start fk-ops-hosts-populator
sleep 5

#This will automate the step to assign a unique id to this zookeeper instance
source /etc/default/megh/env_var
echo $MEGH_INSTANCE_ID > /grid/1/var/lib/zookeeper/myid
chown -R zookeeper:zookeeper /grid/1/var/lib/zookeeper

apt-get install --yes --allow-unauthenticated fk-nagios-common
echo "team_name=Indradhanush" > /etc/default/nsca_wrapper
/etc/init.d/nsca restart

sleep 10