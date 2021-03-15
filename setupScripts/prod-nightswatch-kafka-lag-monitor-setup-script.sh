#!/bin/bash
#setup infra-cli and default srcs.list

echo "deb http://10.47.4.220/repos/infra-cli/3 /" > /etc/apt/sources.list.d/infra-cli-svc.list
echo "deb http://10.47.4.220:80/repos/alertz-stretch-nagios-prod/7 /" >> /etc/apt/sources.list.d/infra-cli-svc.list

apt-get update
apt-get install --yes --allow-unauthenticated infra-cli
apt-get install --yes --allow-unauthenticated python

reposervice --host 10.24.0.41 --port 8080 env --name fk-w3-transact-lag-monitor --appkey fk-w3-transact-lag-monitor-stretch --version HEAD > /etc/apt/sources.list.d/fk-transact-lag-monitor.list

cat <<END >/etc/fk-env
prod
END

echo "prod-nightswatch-kafka-lag-monitor" > /etc/default/fk-w3-transact-lag-monitor-client-bucket

apt-get install --yes --allow-unauthenticated fk-nagios-common
echo "team_name=Indradhanush" > /etc/default/nsca_wrapper
/etc/init.d/nsca restart
sleep 5

apt-get update
apt-get install --yes --allow-unauthenticated fk-w3-transact-lag-monitor