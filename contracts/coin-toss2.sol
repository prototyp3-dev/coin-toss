pragma solidity >=0.7.0 <0.9.0;

import "@cartesi/rollups/contracts/interfaces/IInput.sol";

contract CoinToss {
    int8 constant HEADS = 0;
    int8 constant TAILS = 1;
    address L2_DAPP;

    struct Game {
        mapping (address => int) players; // maps players address to his coin choice
        bool exists;
    }

    mapping (bytes => Game) games; // maps gamekey to game

    function get_gamekey(address player, address opponent) internal pure returns (bytes memory) {
        bytes memory gamekey;
        if (player < opponent) {
            gamekey = abi.encode(player, opponent);
        } else {
            gamekey = abi.encode(opponent, player);
        }

        return gamekey;
    }

    // used to create a game, only the first player chooses a side of the coin
    function play(address opponent, int8 choice) public {
        require(choice == HEADS || choice == TAILS);

        bytes memory gamekey = get_gamekey(msg.sender, opponent);

        require(!games[gamekey].exists);

        Game storage game = games[gamekey];
        if (choice == HEADS) {
            game.players[msg.sender] = HEADS;
            game.players[opponent] = TAILS;
        } else {
            game.players[msg.sender] = TAILS;
            game.players[opponent] = HEADS;
        }
        game.exists = true;
    }

    // second player call to play
    function play(address opponent) public returns (address) {
        bytes memory gamekey = get_gamekey(msg.sender, opponent);

        require(games[gamekey].exists);

        int8 result = l2_coin_toss(gamekey);

        require(result == HEADS || result == TAILS);

        address winner;
        if (games[gamekey].players[msg.sender] == result) {
            winner = msg.sender;
        } else {
            winner = opponent;
        }

        return winner;
    }

    function l2_coin_toss(bytes memory gamekey) private returns (int8) {
        // generate randomness using chainlink
        // calls Cartesi's addInput to run the "game toss" inside Cartesi Machine
        // must send to Rollups {"address1": coin_side, "address2": coin_side, "seed": randomness}
    }

    function announce_winner(address winner) public {
        require(msg.sender == L2_DAPP);

        emit GameResult(winner);
    }

    event GameResult (
        address winner
    );
}