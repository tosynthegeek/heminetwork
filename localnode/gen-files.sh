#!/bin/sh
# Copyright (c) 2025 Hemi Labs, Inc.
# Use of this source code is governed by the MIT License,
# which can be found in the LICENSE file.

set -e

if [ $# != 3 ]; then
	echo "usage: ./gen-files.sh <network> <sync-mode> <profile>"
	exit 1
fi

NET=$1
MODE=$2
PROFILE=$3

if [ "$NET" != "mainnet" ] && [ "$NET" != "testnet" ]; then
	echo "Network must be 'mainnet' or 'testnet'"
	exit 1
fi

if [ "$MODE" != "snap" ] && [ "$MODE" != "archive" ]; then
	echo "Sync Mode must be 'snap' or 'archive'"
	exit 1
fi

if [ "$PROFILE" != "full" ] && [ "$PROFILE" != "hemi" ] && [ "$PROFILE" != "hemi-min" ] && [ "$PROFILE" != "L1" ]; then
	echo "Profile must be 'full', 'hemi', 'hemi-min', or 'L1'"
	exit 1
fi


echo "Setup for $NET (sync mode: $MODE, profile: $PROFILE))"

ENTRYFILE=""
GENESIS=""
ID=""
TBCNET=""
HVMGENESIS=""
HVMGENESISHEADER=""
OVERRIDES=""
BOOTNODES=""

case "$NET" in
mainnet)
	ENTRYFILE="mainnet-entrypointl2.sh"
	GENESIS="genesis.json"
	ID=43111
	TBCNET="mainnet"
	OVERRIDES="--override.ecotone=1725868497 \\
	--override.canyon=1725868497 \\
	--override.cancun=1725868497 \\
	--override.hvm0=1739286001 \\
	--override.isthmus=1751554801 \\
	--override.holocene=1751554801 \\
	--override.granite=1751554801 \\
	--override.fjord=1751554801 \\"
	HVMGENESIS=883092
	HVMGENESISHEADER="0000003efaaa2ba65de684c512bb67ef115298d1d16bcb49b16c02000000000000000000ed31a56788c4488afc4ee69e0791ad6aeeb9ea05f069e0fdde6159068765ad3f4128a96726770217e7f41c86"
	BOOTNODES="--bootnodes=enode://e7970a29d89f8b158371a8d4aca909ee8c1c759e711547b797a6a6f01513c1e7c85121dd2600397ca20cebf3cea21025001be7c0f577b496caf32ea0433a1cfd@34.90.21.246:30303,enode://70877d3aa6c4ccc09d960c269846215d5dcc8bf47013ac532c1ccc3d9cfe61434c96b9d6cad88a96c3f91187fb00214d903a6be6d8e93140ac4a3c099684ce34@34.13.162.152:30303,enode://27f75e68a8c14cae2f4e12f060477c150767e98149e16a448baddc25d800c008edf8b1fefd13b206c27e5473ac9234ba1958a8267fe5272e9de3819ac080bf22@34.13.171.139:30303,enode://588ffb65f841aede8d8f69a3175f9cfed1b79d20d40a7feb8a70e574b5610fb4049bf02f3170f1ae25bff806b2c823653b28af711e1962ea3f45d99d58608191@34.91.216.121:30303,enode://ba86a76186268948bc34b7fa1c2f08c24ed60cda61346cf1a1cca278b0ef1de49e567039952e06e4887a0252974401a6d6729bfc12945c6d8c65eacbf3b11ca7@34.141.148.19:30303"
  ;;
testnet)
	ENTRYFILE="entrypointl2.sh"
	GENESIS="testnet-genesis.json"
	ID=743111
	TBCNET="testnet3"
	OVERRIDES="--override.ecotone=1715865630 \\
	--override.canyon=1715865630 \\
	--override.cancun=1715865630 \\
	--override.hvm0=1733930401 \\
 	--override.isthmus=1748963425 \\
 	--override.holocene=1748963425 \\
 	--override.granite=1748963425 \\
 	--override.fjord=1748963425 \\"
	HVMGENESIS=3522419
	HVMGENESISHEADER="00c05732cdc3e0d654efe86351f0cbfc6c79325e9f9fa7886a39b552f5c4d90700000000dae4079485e26f1f77425b84a13760038a352d07a0fef92b5188bd04c2999162afca58679121011962b9d0a5"
	BOOTNODES="--bootnodes=enode://545da2b44f197091c0ca9283c9c1dd5ffc8562a3cd4a37709a7cd83ca725ecacdb4571dacd916a1455e9dd9f2260e5bc5dddf9fd40ba4601a71b401adbaeec21@34.147.95.117:30303"
  ;;
esac

SYNCMODE=""
OPSYNCMODE=""
case "$MODE" in
snap)
  	SYNCMODE="snap"
  	OPSYNCMODE="execution-layer"
  ;;
archive)
	SYNCMODE="full"
	OPSYNCMODE="consensus-layer"
  ;;
esac

cat >"$ENTRYFILE" <<EOF
#!/bin/sh
# Copyright (c) 2024-2025 Hemi Labs, Inc.
# Use of this source code is governed by the MIT License,
# which can be found in the LICENSE file.

set -xe

if [ -d "/tmp/datadir/geth" ]; then
	echo "geth data dir exists, skipping genesis."
else
	geth init --state.scheme hash --datadir /tmp/datadir/geth /tmp/$GENESIS
fi

geth \\
	--config=/tmp/l2-config.toml \\
	--http \\
	--http.corsdomain=* \\
	--http.vhosts=* \\
	--http.addr=0.0.0.0 \\
	--http.api=web3,eth,txpool,net \\
	--http.port=18546 \\
	--ws \\
	--ws.rpcprefix=/ \\
	--ws.addr=0.0.0.0 \\
	--ws.port=28546 \\
	--ws.origins=* \\
	--ws.api=eth,txpool,net \\
	--syncmode=$SYNCMODE \\
	--gcmode=archive \\
	--maxpeers=100 \\
	--networkid=$ID \\
	--authrpc.vhosts=* \\
	--authrpc.addr=0.0.0.0 \\
	--authrpc.port=8551 \\
	--authrpc.jwtsecret=/tmp/jwt/jwt.hex \\
	--rollup.disabletxpoolgossip=false \\
	--datadir=/tmp/datadir/geth \\
	$OVERRIDES
	--tbc.leveldbhome=/tbcdata/data \\
    --hvm.headerdatadir=/tbcdata/headers \\
	--tbc.network=$TBCNET \\
    --hvm.genesisheader=$HVMGENESISHEADER \\
    --hvm.genesisheight=$HVMGENESIS \\
	$BOOTNODES
EOF

echo "NET=$NET" > .env
echo "PROFILE=$PROFILE" >> .env
echo "OPSYNCMODE=$OPSYNCMODE" >> .env
