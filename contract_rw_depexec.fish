#!/usr/bin/env fish
# set -x
set fish_trace 1
source  ../contract_rw_vars.fish

# print hello

function test_cartesi_voucher
  argparse "p/path=" -- $argv
  or return
  echo "======== $_flag_p "
  set logfile $_flag_path"test.log"
  echo "**** logfile: $logfile" &|tee -a $logfile
  if not docker version >/dev/null
    echo "docker isn't running :-("  &| tee -a $logfile
    return
  end
  docker image inspect coin-toss-contracts >/dev/null 2>&1; and docker image rm coin-toss-contracts; or true
  if not docker buildx bake -f docker-bake.hcl -f docker-bake.override.hcl --load
    echo "Error: docker buildx bake command failed" | tee -a $logfile
    return 1
  end
  fish -c "docker compose -f docker-compose.yml -f docker-compose.override.yml up"&

  set rpc_server_tries_count 0
  set rpc_server_tries_count_cutoff 5


  while true
    echo "()()() while loop in: $logfile"
    if not docker version >/dev/null
      echo "docker isn't running :-( (in the while block loop)"  &| tee -a $logfile
      return
    end
    set hex_response (curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $RPC_URL 2>/dev/null)
    # Check if the response is empty (server might not be running)
    if test -z "$hex_response"
      set $rpc_server_tries_count (math $$rpc_server_tries_count + 1)

      # Check if the counter has reached 10
      if test $$rpc_server_tries_count -eq $rpc_server_tries_count_cutoff
          echo "RPC server check failed 10 times. Exiting..." &| tee -a $logfile
          return
      end

      echo "RPC server not available. Retrying in 10 seconds..."
      sleep 10
      continue
    end

    # Process response
    set hex_number (echo $hex_response | jq -r .result)
    set decimal_number (math $hex_number)
    echo "Current block number is $decimal_number. log: $_flag_p"

    set cut_off_block_load 28 # by this time, all should be loaded

    # Check if the block number is greater than 1
    if test $decimal_number -gt $cut_off_block_load
      echo "Block number is $decimal_number, which is greater than $cut_off_block."
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"set_dapp_address(address)\" $DAPP_ADDRESS"
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"sendInstructionPrompt(string)\" \"When \""
      echo "+++++ conversations count: " &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"current_conversation_id()\"" &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"current_conversation_id()\"" | tr -d '\n'| cut -c 3- | xxd -p -r &| tee -a $logfile
      curl --data '{"id":1337,"jsonrpc":"2.0","method":"evm_increaseTime","params":[864010]}' http://localhost:8545
      curl --data '{"id":1337,"jsonrpc":"2.0","method":"evm_increaseTime","params":[864010]}' http://localhost:8545
      break
    end

    sleep 10
  end

  set db_server_tries_count 0
  set db_server_tries_count_cutoff 5

  while true
    echo "()()() while loop in: $logfile"
    if not docker version >/dev/null
      echo "docker isn't running :-( (in the while block loop)"  &| tee -a $logfile
      return
    end
    set hex_response (curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $RPC_URL 2>/dev/null)
    # Check if the response is empty (server might not be running)
    if test -z "$hex_response"
      set $db_server_tries_count (math $$db_server_tries_count + 1)

      # Check if the counter has reached 10
      if test $$db_server_tries_count -eq $db_server_tries_count_cutoff
          echo "RPC server check failed 10 times. Exiting..." &| tee -a $logfile
          return
      end
      echo "front end RPC server not available. Retrying in 10 seconds..."
      sleep 10
      continue
    end

    # Process response
    set hex_number (echo $hex_response | jq -r .result)
    set decimal_number (math $hex_number)
    echo "Current block number is $decimal_number."

    set cut_off_block_interaction_wait 38 # by this time, all should be loaded
    if test $decimal_number -gt $cut_off_block_interaction_wait
      cd ../rollups-examples/frontend-console/
      # yarn && yarn build
      yarn start notice list &| tee -a $logfile
      yarn start voucher list &| tee -a $logfile
      yarn start voucher execute --index 0 --input 0 &| tee -a $logfile
      cd -

      echo "+++++ conversation by ID: " &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getConversationById(uint256)\" 0" &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getConversationById(uint256)\" 0"  | tr -d '\n'| cut -c 3- | xxd -p -r &| tee -a $logfile
      echo "+++++ prompt for conversation 0: " &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getPromptByConversationId(uint256)\" 0" &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getPromptByConversationId(uint256)\" 0" | tr -d '\n'| cut -c 3- | xxd -p -r &| tee -a $logfile
      echo "+++++ conversation 0 responses count: " &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getConversationResponseCount(uint256)\" 0" &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getConversationResponseCount(uint256)\" 0"  | tr -d '\n'| cut -c 3- | xxd -p -r &| tee -a $logfile
      echo "+++++ conversation 0 response 0: " &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getConversationResponse(uint256,uint256)\" 0 0" &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getConversationResponse(uint256,uint256)\" 0 0"  | tr -d '\n'| cut -c 3- | xxd -p -r &| tee -a $logfile
      echo "+++++ conversation 0 response 1: " &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getConversationResponse(uint256,uint256)\" 0 1" &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getConversationResponse(uint256,uint256)\" 0 1"  | tr -d '\n'| cut -c 3- | xxd -p -r &| tee -a $logfile

      # Submitting ranks for conversation 0
      echo "+++++ submitting ranks for conversation 0: " &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"submitRank(uint256,uint256[])\" 0 [1,0]" &| tee -a $logfile

      # Retrieving and outputting users who submitted ranks for conversation 0
      echo "+++++ retrieving users who submitted ranks for conversation 0: " &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getUsersWhoSubmittedRanks(uint256)\" 0" &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getUsersWhoSubmittedRanks(uint256)\" 0" | tr -d '\n'| cut -c 3- | xxd -p -r &| tee -a $logfile

      # Retrieving ranks submitted by PLAYER1 for conversation 0
      echo "+++++ retrieving ranks submitted by $PLAYER1 for conversation 0: " &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getRanksByUser(uint256,address)\" 0 $PLAYER1" &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getRanksByUser(uint256,address)\" 0 $PLAYER1" | tr -d '\n'| cut -c 3- | xxd -p -r &| tee -a $logfile
      echo "+++++ retrieving rank 1 submitted by $PLAYER1 for conversation 0: " &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getRankByUserAtIndex(uint256,address,uint256)\" 0 $PLAYER1 0" &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getRankByUserAtIndex(uint256,address,uint256)\" 0 $PLAYER1 0" | tr -d '\n'| cut -c 3- | xxd -p -r &| tee -a $logfile
      echo "+++++ retrieving rank 2 submitted by $PLAYER1 for conversation 0: " &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getRankByUserAtIndex(uint256,address,uint256)\" 0 $PLAYER1 1" &| tee -a $logfile
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"getRankByUserAtIndex(uint256,address,uint256)\" 0 $PLAYER1 1" | tr -d '\n'| cut -c 3- | xxd -p -r &| tee -a $logfile
      docker compose -f docker-compose.yml -f docker-compose.override.yml down -v
      # docker images && docker ps -a --no-trunc &&  docker volume ls && docker network ls
      break
    end

    sleep 10
  end
  echo "**** logfile: $logfile" &|tee -a $logfile
end
