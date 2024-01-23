#!/usr/bin/env fish
docker buildx bake -f docker-bake.hcl -f docker-bake.override.hcl machine --load --set \*.args.NETWORK=sepolia
DAPP_NAME="trust-and-teach" docker compose --env-file env.sepolia -f deploy-testnet.yml up #deploy to cartesi factory
DAPP_NAME="trust-and-teach" docker compose --env-file env.<network> -f deploy-testnet.yml down -v #stop docker after finish
DAPP_NAME="trust-and-teach" docker compose --env-file env.sepolia -f docker-compose-testnet.yml up
DAPP_NAME="trust-and-teach" docker compose --env-file env.<network> -f docker-compose-testnet.yml -f docker-compose-host-testnet.yml up # host mode
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"set_dapp_address(address)\" $DAPP_ADDRESS"
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"sendInstructionPrompt(string)\" \"hi. \""


