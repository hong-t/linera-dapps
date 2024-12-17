FROM uhub.service.ucloud.cn/entropypool_public/systemd-ubuntu:20.04

user root

ARG MYSQL_USERNAME
ARG MYSQL_PASSWORD

COPY $GOTAR /$GONAME
RUN tar -C /usr -xzf /$GONAME

RUN apt-get update-y
RUN apt-get install git wget -y
COPY kline-entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/kline-entrypoint.sh

CMD ["/usr/local/bin/kline-entrypoint.sh"]
