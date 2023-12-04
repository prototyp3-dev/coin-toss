// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@cartesi/rollups/contracts/inputs/IInputBox.sol";

contract TrustAndTeach {
    address deployer;
    address public L2_DAPP;
    string public license = "MIT";
    string public llm = "stories15m";
    IInputBox inputBox = IInputBox(0x59b22D57D4f067708AB0c00552767405926dc768);

    struct RankSubmission {
        address user;
        uint256[] ranks;
        uint256 rankingTimestamp; // Added rankingTimestamp to RankSubmission
    }

    struct Conversation {
        address author;
        string prompt;
        string[] responses;
        uint256 rankSubmissionCount;
        mapping(address => RankSubmission) rankSubmissions;
        uint256 createInstructionTimestamp;
        uint256 responseAnnouncedTimestamp;
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
    }

    function cartesiSubmitPrompt(uint256 conversation_id, string memory prompt)
        public
    {
        bytes memory payload = abi.encode(conversation_id, prompt);
        inputBox.addInput(L2_DAPP, payload); // this line gives an error :-(
    }

    function announcePromptResponse(
        uint256 conversation_id,
        string[] memory responses
    ) public {
        // require(msg.sender == L2_DAPP);
        require(conversation_id <= current_conversation_id);
        // adds each response to a conversation as a list of responses
        Conversation storage conversation = conversations[conversation_id];
        conversation.responses = responses; // this is a list of responses to the prompt
        conversation.responseAnnouncedTimestamp = block.timestamp;
        emit PromptResponseAnnounced(conversation_id, responses);
    }

    // get list of users who submitted ranks for a conversation
    function getUsersWhoSubmittedRanks(uint256 conversation_id)
        public
        view
        returns (address[] memory)
    {
        Conversation storage conversation = conversations[conversation_id];
        return users;
    }

    // get ranks submitted by a user for a conversation
    function getRanksByUser(uint256 conversation_id, address user)
        public
        view
        returns (uint256[] memory)
    {
        Conversation storage conversation = conversations[conversation_id];
        RankSubmission storage submission = conversation.rankSubmissions[user];
        return submission.ranks;
    }

    // get conversation id response count
    function getConversationResponseCount(uint256 conversation_id)
        public
        view
        returns (uint256)
    {
        Conversation storage conversation = conversations[conversation_id];
        return conversation.responses.length;
    }

    //get conversation #id response by index
    function getConversationResponse(uint256 conversation_id, uint256 index)
        public
        view
        returns (string memory)
    {
        Conversation storage conversation = conversations[conversation_id];
        return conversation.responses[index];
    }

    // submit rank to a conversation by a user
    function submitRank(uint256 conversation_id, uint256[] memory ranks)
        public
    {
        require(
            conversation_id <= current_conversation_id,
            "Invalid conversation ID"
        );
        Conversation storage conversation = conversations[conversation_id];
        RankSubmission storage submission = conversation.rankSubmissions[msg.sender];
        // Check if the user has not already submitted ranks
        if (submission.user == address(0)) {
            submission.user = msg.sender;
            submission.ranks = ranks;
            conversation.rankSubmissionCount++; // Increment the count as this is a new submission
            submission.rankingTimestamp = block.timestamp; // Set rankingTimestamp for the submission
            emit RankSubmitted(conversation_id, msg.sender, ranks);
        } else {
            // User has already submitted ranks, update the ranks
            submission.ranks = ranks;
            submission.rankingTimestamp = block.timestamp;
            emit RankSubmitted(conversation_id, msg.sender, ranks);
        }
    }

    event RankSubmitted(uint256 conversation_id, address user, uint256[] ranks);

    event PromptSent(uint256 conversation_id, string prompt);
    event PromptResponseAnnounced(uint256 conversation_id, string[] responses);
    event PromptResponsesRanked(uint256 conversation_id, uint256[] ranks);
}
