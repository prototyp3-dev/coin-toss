export USER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
export USER_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export TRUST_AND_TEACH_ADDRESS="0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1"
export DAPP_ADDRESS="0x70ac08179605AF2D9e75782b8DEcDD3c22aA4D0C"
export RPC_URL="http://localhost:8545"

docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $USER_PRIVATE_KEY --rpc-url $RPC_URL $TRUST_AND_TEACH_ADDRESS \"set_dapp_address(address)\" $DAPP_ADDRESS"
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $USER_PRIVATE_KEY --rpc-url $RPC_URL $TRUST_AND_TEACH_ADDRESS \"sendInstructionPrompt(string,uint256)\" \"Once\" 40"
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $USER_PRIVATE_KEY --rpc-url $RPC_URL $TRUST_AND_TEACH_ADDRESS \"getConversationById(uint256)\" 0"

cd ../rollups-examples/frontend-console/
yarn && yarn build
yarn start notice list && yarn start voucher list
yarn start voucher execute --index 0 --input 0
yarn start voucher execute --index 1 --input 0
cd -
