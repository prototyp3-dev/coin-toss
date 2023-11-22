export PLAYER1="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
export PLAYER1_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export PLAYER2="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
export PLAYER2_PRIVATE_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export COIN_TOSS_ADDRESS="0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1"
export DAPP_ADDRESS="0x70ac08179605AF2D9e75782b8DEcDD3c22aA4D0C"
export RPC_URL="http://localhost:8545"

docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"set_dapp_address(address)\" $DAPP_ADDRESS"
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"play(address,string)\" $PLAYER2 \"hi\""
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER2_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"play(address,string)\" $PLAYER1 \"byr\""


cd ../rollups-examples/frontend-console/
yarn && yarn build
yarn start notice list && yarn start voucher list
yarn start voucher execute --index 0 --input 0
cd -
