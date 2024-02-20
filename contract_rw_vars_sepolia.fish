#!/usr/bin/env fish
set CONTRACT_NAME "TrustAndTeach"
set PLAYER1_PRIVATE_KEY "0x24bdc263fd61b12b5995e5120564734f2180e5ce6bdafe3a37342d548d2a5b8f"
set TRUST_AND_TEACH_ADDRESS "0x5873298b68497fad590f68221D9a8d134902DE64"
set DAPP_ADDRESS (cat deployments/sepolia/TrustAndTeach.json | jq -r .deployedTo)
