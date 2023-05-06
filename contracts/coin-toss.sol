pragma solidity >=0.7.0 <0.9.0;

import "@cartesi/rollups/contracts/interfaces/IInput.sol";

contract CoinToss {
    address deployer;
    address L2_DAPP;

    struct Game {
        address winner;
        address pending_player;
        bool exists;
    }

    struct Games {
        uint256 current_match_id; // initial value is 0
        mapping (uint => Game) matches;
    }

    mapping (bytes => Games) games; // maps gamekey to gameID

    constructor() {
        deployer = msg.sender;
    }
    
    function set_dapp_address(address l2_dapp) public {
        require(msg.sender == deployer);

        L2_DAPP = l2_dapp;
    }

    function get_gamekey(address player, address opponent) internal pure returns (bytes memory) {
        bytes memory gamekey;
        if (player < opponent) {
            gamekey = abi.encode(player, opponent);
        } else {
            gamekey = abi.encode(opponent, player);
        }

        return gamekey;
    }

    // used to create or play game between two players
    function play(address opponent) public {
        require(L2_DAPP != address(0));

        bytes memory gamekey = get_gamekey(msg.sender, opponent);
        Game storage game = games[gamekey].matches[games[gamekey].current_match_id];
        
        require(!game.exists || game.pending_player == msg.sender);

        if (!game.exists) {
            game.pending_player = opponent;
            game.exists = true;
        } else if (game.pending_player == msg.sender) {
            l2_coin_toss(gamekey);
        }        
    }

    function l2_coin_toss(bytes memory gamekey) private {
        // generate randomness
        uint256 coin_toss_seed = uint256(blockhash(block.number - 1));
        
        bytes memory payload = abi.encode(gamekey, coin_toss_seed);

        // calls Cartesi's addInput to run the "coin toss" inside Cartesi Machine
        IInput(L2_DAPP).addInput(payload);
    }

    function announce_winner(address player1, address player2, address winner) public {
        require(msg.sender == L2_DAPP && (winner == player1 || winner == player2));

        bytes memory gamekey = get_gamekey(player1, player2);
        Game storage game = games[gamekey].matches[games[gamekey].current_match_id];

        require(game.exists);

        emit GameResult(gamekey, games[gamekey].current_match_id, winner);
        
        game.winner = winner;
        games[gamekey].current_match_id++;
    }

    event GameResult (
        bytes gamekey,
        uint256 gameId,
        address winner
    );
}