# Trust-and-Teach AI solidity contract and Cartesi back-End

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
This requires you to specify the account, which for tesing purposes you can create using foundry
```shell
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast wallet new-mnemonic"
```
and RPC gateway to use when submitting the deploy transaction on the target network, which can be done by defining the following environment variables:

```shell
export MNEMONIC=<user sequence of twelve words>
export RPC_URL=<https://your.rpc.gateway>
```


For example, to deploy to the Sepolia testnet using an Alchemy RPC node, you could execute:

```shell
export MNEMONIC=<user sequence of twelve words>
export RPC_URL=https://eth-sepolia.alchemyapi.io/v2/<USER_KEY>
```

With that in place, you can submit a deploy transaction to the Cartesi DApp Factory contract on the target network by executing the following command:

```shell
DAPP_NAME="trust-and-teach" docker compose --env-file env.<network> -f deploy-testnet.yml up
```

Here, `env.<network>` specifies general parameters for the target network, like its name and chain ID. In the case of Sepolia, the command would be:

```shell
DAPP_NAME="trust-and-teach" docker compose --env-file env.sepolia -f deploy-testnet.yml up
```

This will create a file at `deployments/<network>/trust-and-teach.json` with the deployed contract's address.
Once the command finishes, it is advisable to stop the docker compose and remove the volumes created when executing it.

```shell
DAPP_NAME="trust-and-teach" docker compose --env-file env.<network> -f deploy-testnet.yml down -v
```

After that, a corresponding Cartesi Validator Node must also be instantiated in order to interact with the deployed smart contract on the target network and handle the back-end logic of the DApp.
Aside from the environment variables defined before, the node will also need a secure websocket endpoint for the RPC gateway (WSS URL).

For example, for Sepolia and Alchemy, you would set the following additional variable:

```shell
export WSS_URL=wss://eth-sepolia.alchemyapi.io/v2/<USER_KEY>
```

Then, the node itself can be started by running a docker compose as follows:

```shell
DAPP_NAME="trust-and-teach" docker compose --env-file env.<network> -f docker-compose-testnet.yml up
```

Alternatively, you can also run the node on host mode by executing:

```shell
DAPP_NAME="trust-and-teach" docker compose --env-file env.<network> -f docker-compose-testnet.yml -f docker-compose-host-testnet.yml up
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
ROLLUP_HTTP_SERVER_URL="http://127.0.0.1:5004" python3 trust-and-teach.py
```

The final command will effectively run the back-end and send corresponding outputs to port `5004`.
It can optionally be configured in an IDE to allow interactive debugging using features like breakpoints.

You can also use a tool like [entr](https://eradman.com/entrproject/) to restart the back-end automatically when the code changes. For example:

```shell
ls *.py | ROLLUP_HTTP_SERVER_URL="http://127.0.0.1:5004" entr -r python3 trust-and-teach.py
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


```shell
export USER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
export USER_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export TRUST_AND_TEACH="0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1"
export DAPP_ADDRESS="0x70ac08179605AF2D9e75782b8DEcDD3c22aA4D0C"
export RPC_URL="http://localhost:8545"
```

> [!NOTE]
> The image `ghcr.io/foundry-rs/foundry` its from [Foundry](https://book.getfoundry.sh/getting-started/installation) and allow us to use the [cast](https://book.getfoundry.sh/reference/cast/cast) command to send transactions.

1. Execute the `set_dapp_address` method of the `trust-and-teach` contract to set the rollup contract address. This step is to allow the layer-1 contract to send inputs to the Cartesi Rollups DApp.

```shell
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $USER_PRIVATE_KEY --rpc-url $RPC_URL $TRUST_AND_TEACH \"set_dapp_address(address)\" $DAPP_ADDRESS"
```

2. Execute the `sendInstructionPrompt` method passing the prompt and the number of total tokens in the response that include the generated tokens.

```shell
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $USER_PRIVATE_KEY --rpc-url $RPC_URL $TRUST_AND_TEACH_ADDRESS \"sendInstructionPrompt(string,uint256)\" \"Once\" 10"

```

3. (Optional) Check that LLM generated the response and Cartesi backend created the notices
```shell
docker logs trust-and-teach-cartesi-server_manager-1
```

3. (Optional) Check the notice and the voucher using the [frontend-console](https://github.com/cartesi/rollups-examples/tree/main/frontend-console).

4. Wait for the dispute period to end to execute the voucher. The dispute period is set to 5 minutes in testnet^, as can be seen in `docker-compose-testnet.yml`. If running locally advance the time with the following command:

```shell
curl --data '{"id":1337,"jsonrpc":"2.0","method":"evm_increaseTime","params":[864010]}' http://localhost:8545
```

5. The LLM will output 2 vouchers; one for each response. Execute the vouchers using the `frontend-console`.
```shell
yarn start voucher execute --index 0 --input 0
yarn start voucher execute --index 1 --input 0
```

7. Check the value of the `last_game` variable in the `TrustAndTeach` smart contract to see the persisted result in layer-1 due to the voucher execution.
6. You can see the 

```shell
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --rpc-url $RPC_URL ${TRUST_AND_TEACH} \"last_game()\""
```

^ **The value was chosen for testing purposes, do not use it in production!!!** The default value is 1 week.



**milestone: splitting a payload into multiple vouchers**
works:
- split LLM response into multiple vouchers
- automated testing for multiple vouchers
(details below)
Problems I'm currently working on:
- even though 200+ random :alpha: + space character strings work, the llama2.c inference doesn't post a notice.
Todo: 
- run on test net
- write docs
- simple ui

