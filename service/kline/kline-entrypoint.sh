#!/bin/bash

export all_proxy=
git clone https://github.com/hong-t/linera-dapps.git
cd linera-dapps/service/kline

export GOROOT=/usr/go/
export PATH=/usr/go/bin:$PATH
export GOPROXY=https://goproxy.cn,direct

make build
./zeus/output/linux/amd64/zeus run

