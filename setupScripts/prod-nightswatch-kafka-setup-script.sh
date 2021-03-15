#!/bin/bash

echo "deb http://10.47.4.220/repos/infra-cli/7 /" > /etc/apt/sources.list.d/infra-cli.list
echo "deb http://10.47.4.220:80/repos/alertz-stretch-nagios-prod/7 /" >> /etc/apt/sources.list.d/infra-cli-svc.list
apt-get update
apt-get install --yes --allow-unauthenticated infra-cli

reposervice  --host 10.24.0.41 --port 8080 env -name fpg-paas-stretch  --appkey dummy > /etc/apt/sources.list.d/fk-fpg-pass.list
reposervice  --host 10.24.0.41 --port 8080 env -name fk-3p-kafka-2.4.0  --appkey dummy > /etc/apt/sources.list.d/fk-3p-kafka.list

echo "IAAS_SETUP_ACTION is $IAAS_SETUP_ACTION"


function mount_disk() {
  DEV=/dev/$1
  DIR=/grid/$1
  if [ -e "$DEV" ]; then
    if [ "$IAAS_SETUP_ACTION" == "create" ]
    then
      mkfs.ext4 "$DEV"
    fi
    echo "$DEV $DIR ext4 rw,noatime,nodiratime 0 0" >>/etc/fstab
    mkdir -p "$DIR"
    mount "$DIR"
    mkdir -p "$DIR/kafka"
    mkdir -p "$DIR/kafka/nightswatch"
    chown -R kafka:kafka "$DIR/kafka"
  fi
}


function set_config() {

    file="/etc/default/fk-3p-kafka.env"
    if [ -f "$file" ]
    then
        echo "$file already present."
        cat $file
    else
        echo "$file not found. Updating configs."
        echo "export KAFKA_CONFIG_BROKER_ID=104
export KAFKA_CONFIG_BUCKET=prod-nightswatch-kafka-config" > $file
    fi
}

set_config
mount_disk vdb

ip=$(hostname -i)

apt-get update
apt-get install --yes --allow-unauthenticated cosmos-jmx cosmos-collectd fk-nagios-common
apt-get install --yes --allow-unauthenticated fpg-hosts-populator

echo "team_name=Indradhanush" > /etc/default/nsca_wrapper
echo "prod-nightswatch-zk/etc-hosts" > /usr/local/fpg-hosts-populator/buckets/zk.conf

/etc/init.d/fpg-hosts-populator start
sleep 3

apt-get install --yes --allow-unauthenticated fk-3p-kafka

echo "*/1 * * * * root sh /usr/share/fk-3p-kafka/alerts/check_process.sh" > /etc/cron.d/kafka-service-alerts

/etc/init.d/fk-config-service-confd restart
/etc/init.d/nsca restart