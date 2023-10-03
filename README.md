# coin-toss DApp

```
Cartesi Rollups version: 1.x
```

This DApp is a coin toss game between two players. The purpose of this example is to illustrate the cycle of Layer-1 to Layer-2 to Layer-1 again. The smart contract in the contracts folder handles the game logic, and the Cartesi Machine is the game "engine" (coin toss). After the machine runs the game and decides on the winner, it generates a voucher to send the result back to Layer-1 when executed. The game workflow is as follows:

1. The player calls the `play` method of the `CoinToss` contract passing his opponent's address to create a game.
2. The opponent calls the same `play` method passing the challenger's address. Now that both players decided to play, the algorithm will generate randomness and send an input to the Cartesi Rollups with the players and the randomness.^
3. Inside the Cartesi Machine the game between the players is run using the randomness provided as seed. Once the winner is settled, the Cartesi DApp generates a voucher.
4. Waits for the epoch and the dispute period to end so the voucher can be validated and executed.^^
5. Execute the voucher.^^^


^ The Cartesi Machine is devoid of any source of entropy for it to be deterministic, so an external randomness is needed.

^^ Since Cartesi Rollups is an Optimistic Rollup solution, we need to wait for the dispute period to end so the state of the DApp is persisted. After that, vouchers can be executed to trigger changes in layer-1.

^^^ When executed, the voucher triggers the `announce_winner` function of the `CoinToss` contract. This function updates the structure that stores the game, emits a `GameResult` event, and increments the game counter for the players. In case they decide to start a new game.

## Contracts

The DApp uses only one smart contract, the different versions provided differ only in how the randomness is generated. The one in the localhost directory uses de block hash as randomness and is suitable for local tests (**Do not use such a thing in production**). The other uses [Chainlink](https://docs.chain.link/getting-started/conceptual-overview), an external network that provides trusted randomness for Blockchain. The approach using Chainlink needs different contracts for different networks since it has to request the randomness from a Chainlink contract deployed on the same network.

## Building

To build the application, run the following command:

```shell
docker buildx bake -f docker-bake.hcl -f docker-bake.override.hcl --load
```

## Running

To start the application, execute the following command:

```shell
docker compose -f docker-compose.yml -f docker-compose.override.yml up
```

The application can afterwards be shut down with the following command:

```shell
docker compose -f docker-compose.yml -f docker-compose.override.yml down -v
```

### Deploying DApps

Deploying a new Cartesi DApp to a blockchain requires creating a smart contract on that network, as well as running a validator node for the DApp.

The first step is to build the DApp's back-end machine, which will produce a hash that serves as a unique identifier.

```shell
docker buildx bake -f docker-bake.hcl -f docker-bake.override.hcl machine --load --set *.args.NETWORK=sepolia
```

Once the machine docker image is ready, we can use it to deploy a corresponding Rollups smart contract.
This requires you to specify the account and RPC gateway to use when submitting the deploy transaction on the target network, which can be done by defining the following environment variables:

```shell
export MNEMONIC=<user sequence of twelve words>
export RPC_URL=<https://your.rpc.gateway>
```

For example, to deploy to the Goerli testnet using an Alchemy RPC node, you could execute:

```shell
export MNEMONIC=<user sequence of twelve words>
export RPC_URL=https://eth-goerli.alchemyapi.io/v2/<USER_KEY>
```

With that in place, you can submit a deploy transaction to the Cartesi DApp Factory contract on the target network by executing the following command:

```shell
DAPP_NAME="coin-toss" docker compose --env-file env.<network> -f deploy-testnet.yml up
```

Here, `env.<network>` specifies general parameters for the target network, like its name and chain ID. In the case of Goerli, the command would be:

```shell
DAPP_NAME="coin-toss" docker compose --env-file env.sepolia -f deploy-testnet.yml up
```

This will create a file at `deployments/<network>/coin-toss.json` with the deployed contract's address.
Once the command finishes, it is advisable to stop the docker compose and remove the volumes created when executing it.

```shell
DAPP_NAME="coin-toss" docker compose --env-file env.<network> -f deploy-testnet.yml down -v
```

After that, a corresponding Cartesi Validator Node must also be instantiated in order to interact with the deployed smart contract on the target network and handle the back-end logic of the DApp.
Aside from the environment variables defined before, the node will also need a secure websocket endpoint for the RPC gateway (WSS URL).

For example, for Goerli and Alchemy, you would set the following additional variable:

```shell
export WSS_URL=wss://eth-goerli.alchemyapi.io/v2/<USER_KEY>
```

Then, the node itself can be started by running a docker compose as follows:

```shell
DAPP_NAME="coin-toss" docker compose --env-file env.<network> -f docker-compose-testnet.yml up
```

Alternatively, you can also run the node on host mode by executing:

```shell
DAPP_NAME="coin-toss" docker compose --env-file env.<network> -f docker-compose-testnet.yml -f docker-compose-host-testnet.yml up
```

## Running the back-end in host mode

When developing an application, it is often important to easily test and debug it. For that matter, it is possible to run the Cartesi Rollups environment in [host mode](https://github.com/cartesi/rollups-examples/tree/main/README.md#host-mode), so that the DApp's back-end can be executed directly on the host machine, allowing it to be debugged using regular development tools such as an IDE.

The host environment can be executed with the following command:

```shell
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose-host.yml up
```

This DApp's back-end is written in Python, so to run it in your machine you need to have `python3` installed.

In order to start the back-end, run the following commands in a dedicated terminal:

```shell
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
ROLLUP_HTTP_SERVER_URL="http://127.0.0.1:5004" python3 coin-toss.py
```

The final command will effectively run the back-end and send corresponding outputs to port `5004`.
It can optionally be configured in an IDE to allow interactive debugging using features like breakpoints.

You can also use a tool like [entr](https://eradman.com/entrproject/) to restart the back-end automatically when the code changes. For example:

```shell
ls *.py | ROLLUP_HTTP_SERVER_URL="http://127.0.0.1:5004" entr -r python3 coin-toss.py
```

After the back-end successfully starts, it should print an output like the following:

```log
INFO:__main__:HTTP rollup_server url is http://127.0.0.1:5004
INFO:__main__:Sending finish
```

After that, you can interact with the application normally [as explained above](#interacting-with-the-application).


## Interacting with the DApp

Before beginning the interaction, declare the variables that we will be using. So first, go to a separate terminal window and execute the commands below to initialize the variables.

> [!IMPORTANT]
> The values used through this interaction consider that the example is running locally. The contracts addresses can be found in the `deployments`.

> [!IMPORTANT]
> If running in testnet, remember to transfer some [LINK](https://faucets.chain.link/) tokens to the CoinToss contract so it can pay the randomness generated by the Chainlink network.

```shell
export PLAYER1="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
export PLAYER1_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export PLAYER2="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
export PLAYER2_PRIVATE_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export COIN_TOSS_ADDRESS="0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1"
export DAPP_ADDRESS="0x70ac08179605AF2D9e75782b8DEcDD3c22aA4D0C"
export RPC_URL="http://localhost:8545"
```

> [!NOTE]
> The image `ghcr.io/foundry-rs/foundry` its from [Foundry](https://book.getfoundry.sh/getting-started/installation) and allow us to use the [cast](https://book.getfoundry.sh/reference/cast/cast) command to send transactions.

1. Execute the `set_dapp_address` method of the `coin-toss` contract to set the rollup contract address. This step is to allow the layer-1 contract to send inputs to the Cartesi Rollups DApp.

```shell
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"set_dapp_address(address)\" $DAPP_ADDRESS"
```

2. Execute the `play` method passing the opponent's address to challenge him for a coin toss game.

```shell
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"play(address)\" $PLAYER2"
```

3. The challenged player executes the same `play` method passing the challenger address. The input is then fetched by the Cartesi Node the coin toss is executed inside the Cartesi Machine. A notice and a voucher are generated.

```shell
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER2_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"play(address)\" $PLAYER1"
```

4. (Optional) Check the notice and the voucher using the [frontend-console](https://github.com/cartesi/rollups-examples/tree/main/frontend-console).
5. Wait for the dispute period to end to execute the voucher. The dispute period is set to 5 minutes in testnet^, as can be seen in `docker-compose-testnet.yml`. If running locally advance the time with the following command:

```shell
curl --data '{"id":1337,"jsonrpc":"2.0","method":"evm_increaseTime","params":[864010]}' http://localhost:8545
```

6. Execute the voucher using the `frontend-console`.
```shell
yarn start voucher execute --index 0 --input 0
```

7. Check the value of the `last_game` variable in the `CoinToss` smart contract to see the persisted result in layer-1 due to the voucher execution.

```shell
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --rpc-url $RPC_URL ${COIN_TOSS_ADDRESS} \"last_game()\""
```

^ **The value was chosen for testing purposes, do not use it in production!!!** The default value is 1 week.