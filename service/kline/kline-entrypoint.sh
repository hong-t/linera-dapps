#!/bin/bash

while true
do
git clone https://github.com/hong-t/linera-dapps.git
[ 0 -eq $? ] && break
sleep 30
done

cd linera-dapps/service/kline

export GOROOT=/usr/go/
export PATH=/usr/go/bin:$PATH
export GOPROXY=https://goproxy.cn,direct

while true
do
MYSQL_HOST=`curl http://${ENV_CONSUL_HOST}:${ENV_CONSUL_PORT}/v1/agent/health/service/name/mysql.npool.top | jq '.[0] | .Service | .Address' | awk -F '"' '{ print $2 }'`
[ "x" != "x$MYSQL_HOST" ] && break
sleep 30
done

sed -i "s/localhost/$MYSQL_HOST'/g"  config/config.toml
sed -i "s/12345679/$MYSQL_PASSWORD'/g"  config/config.toml

make build
./zeus/output/linux/amd64/zeus run
