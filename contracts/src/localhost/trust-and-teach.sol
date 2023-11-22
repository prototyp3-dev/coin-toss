// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@cartesi/rollups/contracts/inputs/IInputBox.sol";

contract TrustAndTeach {
    address deployer;
    address public L2_DAPP;
    Game public last_game;
    IInputBox inputBox = IInputBox(0x59b22D57D4f067708AB0c00552767405926dc768);

    struct Game {
        address winner;
        address pending_player;
        bool exists;
    }

    struct Games {
        uint256 current_match_id; // initial value is 0
        mapping(uint256 => Game) matches;
    }

    mapping(bytes => Games) games; // maps gamekey to gameID

    struct Conversation {
        address author;
        string prompt;
        string[] responses;
        uint256[] ranks; // most relevent is 0
        uint256 createInstructionTimestamp;
        uint256 responseAnnouncedTimestamp;
        uint256 rankingTimestamp;
    }

    uint256 public current_conversation_id = 0; // initial value is 0
    mapping(uint256 => Conversation) conversations;

    constructor() {
        deployer = msg.sender;
    }

    function set_dapp_address(address l2_dapp) public {
        require(msg.sender == deployer);

        L2_DAPP = l2_dapp;
    }

    function get_gamekey(address player, address opponent)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory gamekey;
        if (player < opponent) {
            gamekey = abi.encode(player, opponent);
        } else {
            gamekey = abi.encode(opponent, player);
        }

        return gamekey;
    }

    // used to create or play game between two players
    function sendInstructionPrompt(string memory prompt) public {
        // require(L2_DAPP != address(0));
        Conversation storage conversation = conversations[
            current_conversation_id
        ];
        conversation.author = msg.sender;
        conversation.prompt = prompt;
        conversation.createInstructionTimestamp = block.timestamp;
        cartesiSubmitPrompt(current_conversation_id, prompt);
        emit PromptSent(current_conversation_id, prompt);
        current_conversation_id++;

        // bytes memory gamekey = get_gamekey(msg.sender, opponent);
        // Game storage game = games[gamekey].matches[
        //     games[gamekey].current_match_id
        // ];

        // require(!game.exists || game.pending_player == msg.sender);

        // if (!game.exists) {
        //     game.pending_player = opponent;
        //     game.exists = true;
        // } else if (game.pending_player == msg.sender) {
        //     l2_coin_toss(gamekey, prompt);
        //     game.pending_player = address(0);
        // }
    }

    function cartesiSubmitPrompt(uint256 conversation_id, string memory prompt)
        public
    {
        bytes memory payload = abi.encode(conversation_id, prompt);
        inputBox.addInput(L2_DAPP, payload); // this line gives an error :-(
    }

    // function l2_coin_toss(bytes memory gamekey, string memory prompt) private {
    //     // generate randomness
    //     uint256 coin_toss_seed = uint256(blockhash(block.number - 1));

    //     bytes memory payload = abi.encode(gamekey, coin_toss_seed, prompt);

    //     // calls Cartesi's addInput to run the "coin toss" inside Cartesi Machine
    //     inputBox.addInput(L2_DAPP, payload);
    // }

    function announce_winner(
        address player1,
        address player2,
        address winner
    ) public {
        require(
            msg.sender == L2_DAPP && (winner == player1 || winner == player2)
        );

        bytes memory gamekey = get_gamekey(player1, player2);
        Game storage game = games[gamekey].matches[
            games[gamekey].current_match_id
        ];

        require(game.exists);

        emit GameResult(gamekey, games[gamekey].current_match_id, winner);

        game.winner = winner;
        games[gamekey].current_match_id++;

        last_game = game;
    }

    event GameResult(bytes gamekey, uint256 gameId, address winner);
    event PromptSent(uint256 conversation_id, string prompt);
    event PromptResponseAnnounced(uint256 conversation_id, string[] responses);
    event PromptResponsesRanked(uint256 conversation_id, uint256[] ranks);
}
