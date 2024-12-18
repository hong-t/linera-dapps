FROM uhub.service.ucloud.cn/entropypool_public/systemd-ubuntu:20.04

user root

ARG ALL_PROXY
ARG GONAME
ARG GOTAR
ARG MYSQL_USERNAME
ARG MYSQL_PASSWORD

COPY $GOTAR /$GONAME
RUN tar -C /usr -xzf /$GONAME

RUN apt-get update -y
RUN apt-get install git wget make curl jq vim -y
COPY kline-entrypoint.sh /usr/local/bin
RUN echo "#!/bin/sh" > /usr/local/bin/entrypoint.sh
RUN echo "all_proxy=$ALL_PROXY /usr/local/bin/kline-entrypoint.sh" >> /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/kline-entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

CMD ["/usr/local/bin/entrypoint.sh"]
