#!/bin/bash

function cleanup() {
  kill -15 `ps | grep linera-proxy | awk '{print $1}'` > /dev/null 2>&1
  kill -15 `ps | grep linera-server | awk '{print $1}'` > /dev/null 2>&1
  kill -15 `ps | grep linera | awk '{print $1}'` > /dev/null 2>&1
  kill -15 `ps | grep socat | awk '{print $1}'` > /dev/null 2>&1
}

cleanup

unset RUSTFLAGS
unset TMPDIR
unset ALL_PROXY
unset all_proxy

cargo build --release --target wasm32-unknown-unknown

WALLET_BASE=/tmp/linera/dapps
mkdir -p $WALLET_BASE
rm $WALLET_BASE/* -rf

unset all_proxy
unset ALL_PROXY

NETWORK_ID=1

case $NETWORK_ID in
  1)
    WALLET_50_PUBLIC_IPORT='210.209.69.38:23301'
    LOCAL_IP='172.21.132.203'
    ;;
  2)
    WALLET_50_PUBLIC_IPORT='172.16.31.73:31130'
    LOCAL_IP='172.16.31.73'
    ;;
  3)
    WALLET_50_PUBLIC_IPORT='172.16.31.73:41150'
    LOCAL_IP='localhost'
    ;;
esac

BLUE='\033[1;34m'
YELLOW='\033[1;33m'
LIGHTGREEN='\033[1;32m'
NC='\033[0m'

PROJECT_ROOT=$HOME/linera-project
mkdir -p $PROJECT_ROOT

function print() {
  echo -e $1$2$3$NC
}

function create_wallet() {
  export LINERA_WALLET_$1=$WALLET_BASE/wallet_$1.json
  export LINERA_STORAGE_$1=rocksdb:$WALLET_BASE/client_$1.db

  linera -w $1 wallet init --faucet http://localhost:40080 --with-new-chain
  linera -w $1 wallet show
}

function __run_service() {
  linera -w $1 service --port $2 --external-signing false
  if [ ! $? -eq 0 ]; then
    echo "Run with official release"
    linera -w $1 service --port $2
  fi
}

function run_service () {
  local_port=`expr 31080 + $1`
  pub_port=`expr 41100 + $1`

  __run_service $1 $local_port > $PROJECT_ROOT/service_$local_port.log 2>&1 &

  sleep 3
  socat TCP4-LISTEN:$pub_port TCP4:localhost:$local_port
}

create_wallet 50

wallet_50_default_chain=`linera --with-wallet 50 wallet show | grep "Public Key" | awk '{print $2}'`
wallet_50_owner=`linera --with-wallet 50 wallet show | grep "Owner" | awk '{print $4}'`

####
## Use WLINERA and SWAP application created by deploy-local.sh
####

swap_creation_chain=`grep "SWAP_CREATION_CHAIN" ${PROJECT_ROOT}/.local-defi-materials | awk -F '=' '{print $2}'`
swap_creation_owner=`grep "SWAP_CREATION_OWNER" ${PROJECT_ROOT}/.local-defi-materials | awk -F '=' '{print $2}'`
swap_appid=`grep "SWAP_APPID" ${PROJECT_ROOT}/.local-defi-materials | awk -F '=' '{print $2}'`
swap_workaround_creation_chain_rpc_endpoint=`grep "SWAP_WORKAROUND_CREATION_CHAIN_RPC_ENDPOINT" ${PROJECT_ROOT}/.local-defi-materials | awk -F '=' '{print $2}'`
wlinera_appid=`grep "WLINERA_APPID" ${PROJECT_ROOT}/.local-defi-materials | awk -F '=' '{print $2}'`

print $'\U01f499' $LIGHTGREEN " WLINERA application"
echo -e "    Application ID: $BLUE$wlinera_appid$NC"

print $'\U01f499' $LIGHTGREEN " Swap application"
echo -e "    Application ID: $BLUE$swap_appid$NC"
echo -e "    Creation chain: $BLUE$swap_creation_chain$NC"
echo -e "    Creation owner: $BLUE$swap_creation_owner$NC"

print $'\U01F4AB' $YELLOW " Deploying my ERC20 application ..."
erc20_1_bid=`linera --with-wallet 50 publish-bytecode ./target/wasm32-unknown-unknown/release/erc20_{contract,service}.wasm`
erc20_1_appid=`linera --with-wallet 50 create-application $erc20_1_bid \
    --json-argument '{"initial_supply":"21000000","name":"Test Linera ERC20 Token","symbol":"TLMY","decimals":18,"initial_currency":"0.00001","fixed_currency":false,"fee_percent":"0"}' \
    --json-parameters '{"initial_balances":{"{\"chain_id\":\"'$swap_creation_chain'\",\"owner\":\"User:'$swap_creation_owner'\"}":"5000000."},"swap_application_id":"'$swap_appid'"}' \
    `
print $'\U01f499' $LIGHTGREEN " ERC20 application TLMY deployed"
echo -e "    Bytecode ID:    $BLUE$erc20_1_bid$NC"
echo -e "    Application ID: $BLUE$erc20_1_appid$NC"

linera --with-wallet 50 request-application $wlinera_appid
linera --with-wallet 50 request-application $swap_appid

function print_apps() {
  print $'\U01F4AB' $YELLOW " $1"
  echo -e "  Default Chain:  $LIGHTGREEN$3$NC"
  echo -e "  Owner:          $LIGHTGREEN$4$NC"
  echo -e "    Swap:         $BLUE$2/chains/$3/applications/$swap_appid$NC"
  echo -e "    WLINERA:      $BLUE$2/chains/$3/applications/$wlinera_appid$NC"
  echo -e "    TLMY:         $BLUE$2/chains/$3/applications/$erc20_1_appid$NC"
}

HTTP_HOST="http://$WALLET_50_PUBLIC_IPORT"
chain=`linera --with-wallet 50 wallet show | grep "Public Key" | awk '{print $2}'`
owner=`linera --with-wallet 50 wallet show | grep "Owner" | awk '{print $4}'`
print_apps "Wallet 50" $HTTP_HOST $chain $owner

wallet_50_erc20_1_service="http://$LOCAL_IP:31130/chains/$chain/applications/$erc20_1_appid"
wallet_50_wlinera_service="http://$LOCAL_IP:31130/chains/$chain/applications/$wlinera_appid"
wallet_50_swap_service="http://$LOCAL_IP:31130/chains/$chain/applications/$swap_appid"
wallet_50_default_chain=$chain
wallet_50_owner=$owner

wallet_50_public_erc20_1_service="$HTTP_HOST/chains/$chain/applications/$erc20_1_appid"
wallet_50_public_wlinera_service="$HTTP_HOST/chains/$chain/applications/$wlinera_appid"
wallet_50_public_swap_service="$HTTP_HOST/chains/$chain/applications/$swap_appid"

sed -i '/ERC20_TLMY_APPID/d' $PROJECT_ROOT/.local-defi-materials
echo "ERC20_TLMY_APPID=$erc20_1_appid" >> $PROJECT_ROOT/.local-defi-materials

####
## We should
##   1 subscribe to pool creator chain
##   2 authorize balance from wallet 13 default chain to swap pool
## Swap will subscribe to chain directly when it's pool is created
####

run_service 50 &

sleep 5

####
## We should request our application on swap chain firstly and this may be not needed in future
####
print $'\U01F4AB' $YELLOW " Request TLMY on SWAP creator chain..."
curl -H 'Content-Type: application/json' -X POST \
    -d '{ "query": "mutation { requestApplication(chainId: \"'$swap_creation_chain'\", applicationId: \"'$erc20_1_appid'\", targetChainId: \"'$wallet_50_default_chain'\") }" }' \
    $swap_workaround_creation_chain_rpc_endpoint
echo

print $'\U01F4AB' $YELLOW " Wait for requestApplication execution..."
sleep 3

####
## If we create TLMY/WLINERA pool in swap later, we don't need to subscribe here
####

print $'\U01F4AB' $YELLOW " Subscribe WLINERA creator chain..."
curl -H 'Content-Type: application/json' -X POST -d '{ "query": "mutation { subscribeCreatorChain }"}' $wallet_50_wlinera_service
echo
print $'\U01F4AB' $YELLOW " Subscribe swap creator chain..."
curl -H 'Content-Type: application/json' -X POST -d '{ "query": "mutation { subscribeCreatorChain }"}' $wallet_50_swap_service
echo

print $'\U01F4AB' $YELLOW " Wait for subscription execution..."
sleep 3

print $'\U01F4AB' $YELLOW " Authorize ERC20 to swap application..."
curl -H 'Content-Type: application/json' -X POST -d "{ \"query\": \"mutation { approve(spender: {chain_id: \\\"$swap_creation_chain\\\", owner:\\\"Application:$swap_appid\\\"},value:\\\"4500000.\\\")}\"}" $wallet_50_erc20_1_service
echo

####
## We don't have any WLINERA here, so if we would like to create TLMY/WLINERA pool, we should mint it with native token
## After we mint WLINERA, we should authorize to swap application
####
print $'\U01F4AB' $YELLOW " Mint WLINERA..."
curl -H 'Content-Type: application/json' -X POST -d '{ "query": "mutation { mint(amount: \"2.2318\") }"}' $wallet_50_wlinera_service
echo

print $'\U01F4AB' $YELLOW " Wait for mint execution..."
sleep 3

print $'\U01F4AB' $YELLOW " Authorize WLINERA to swap application..."
curl -H 'Content-Type: application/json' -X POST -d "{ \"query\": \"mutation { approve(spender: {chain_id: \\\"$swap_creation_chain\\\", owner:\\\"Application:$swap_appid\\\"},value:\\\"2.\\\")}\"}" $wallet_50_wlinera_service
echo

print $'\U01F4AB' $YELLOW " Wait for authorization..."
sleep 3

print $'\U01F4AB' $YELLOW " Create liquidity pool by ERC20 1 creator..."
curl -H 'Content-Type: application/json' -X POST -d "{ \"query\": \"mutation { createPool(token0: \\\"$erc20_1_appid\\\", token1: \\\"$wlinera_appid\\\", amount0Initial:\\\"5\\\", amount1Initial:\\\"1\\\", amount0Virtual:\\\"5\\\", amount1Virtual:\\\"1\\\")}\"}" $wallet_50_swap_service
echo

print $'\U01F4AB' $YELLOW " Query ERC20 allowance and balance with..."
print $'\U01F4AB' $LIGHTGREEN " $wallet_50_public_erc20_1_service"
print $'\U01F4AB' $LIGHTGREEN " $wallet_50_public_wlinera_service"
echo -e "query {\n\
  allowance(\n\
    owner: {\n\
      chain_id:\"$wallet_50_default_chain\",\n\
      owner:\"User:$wallet_50_owner\"\n\
    },\n\
    spender: {\n\
      chain_id:\"$swap_creation_chain\",\n\
      owner:\"Application:$swap_appid\"\n\
    }\n\
  )\n\
  balanceOf(owner: {\n\
    chain_id:\"$wallet_50_default_chain\",\n\
    owner:\"User:$wallet_50_owner\"\n\
  })\n\
  totalSupply\n\
  name\n\
  symbol\n\
  decimals\n\
}"

print $'\U01F4AB' $YELLOW " Created pool with..."
print $'\U01F4AB' $LIGHTGREEN " $wallet_50_public_swap_service"
echo -e "mutation {\n\
  createPool (\n\
    token0: \"$erc20_1_appid\",\n\
    token1: \"$wlinera_appid\",\n\
    amount0Initial: \"5\",\n\
    amount1Initial: \"1\",\n\
    amount0Virtual: \"5\",\n\
    amount1Virtual: \"1\",\n\
  )\n\
}"

print $'\U01F4AB' $YELLOW " Add liquidity with..."
print $'\U01F4AB' $LIGHTGREEN " $wallet_50_public_swap_service"
echo -e "mutation {\n\
  addLiquidity (\n\
    token0: \"$erc20_1_appid\",\n\
    token1: \"$wlinera_appid\",\n\
    amount0Desired: \"5\",\n\
    amount1Desired: \"1\",\n\
    amount0Min: \"5\",\n\
    amount1Min: \"1\",\n\
    deadline: 0,\n\
  )\n\
}"

print $'\U01F4AB' $YELLOW " Remove liquidity with..."
print $'\U01F4AB' $LIGHTGREEN " $wallet_50_public_swap_service"
echo -e "mutation {\n\
  removeLiquidity (\n\
    token0: \"$erc20_1_appid\",\n\
    token1: \"$wlinera_appid\",\n\
    liquidity: \"2\",\n\
    amount0Min: \"0.2\",\n\
    amount1Min: \"0.2\",\n\
    deadline: 0,\n\
  )\n\
}"

print $'\U01F4AB' $YELLOW " Swap with..."
print $'\U01F4AB' $LIGHTGREEN " $wallet_50_public_swap_service"
echo -e "mutation {\n\
  swap (\n\
    token0: \"$erc20_1_appid\",\n\
    token1: \"$linera_appid\",\n\
    amount0In: \"1.\",\n\
    amount1In: \"1.\",\n\
    amount0OutMin: \"0.01\",\n\
    amount1OutMin: \"0.01\",\n\
  )\n\
}"

print $'\U01F4AB' $YELLOW " Query pools with..."
print $'\U01F4AB' $LIGHTGREEN " $wallet_50_public_swap_service"
echo -e "query {\n\
  getPools {\n\
    id\n\
    token0\n\
    token1\n\
    poolFeePercent\n\
    price0Cumulative\n\
    price1Cumulative\n\
    amount0Initial\n\
    amount1Initial\n\
    kLast\n\
    blockTimestamp\n\
    protocolFeePercent\n\
    virtualInitialLiquidity\n\
    reserve0\n\
    reserve1\n\
    erc20 {
      balances\n\
      totalSupply\n\
    }\n\
    feeTo\n\
    feeToSetter\n\
  }\n\
}"

print $'\U01F4AB' $YELLOW " Mint WLINERA with..."
print $'\U01F4AB' $LIGHTGREEN " $wallet_50_public_wlinera_service"
echo -e "mutation {\n\
  mint(amount: \"1.\")\n\
}"

trap cleanup INT
read -p "  Press any key to exit"
print $'\U01f499' $LIGHTGREEN " Exit ..."

cleanup

