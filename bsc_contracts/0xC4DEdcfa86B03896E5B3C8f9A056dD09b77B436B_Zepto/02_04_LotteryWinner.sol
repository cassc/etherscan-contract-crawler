// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// create subscription, set consumer and fund it
// https://docs.chain.link/docs/get-a-random-number/
// https://vrf.chain.link/bsc/new

contract LotteryWinner is VRFConsumerBaseV2 {
    // MUST be passed in constructor!
    VRFCoordinatorV2Interface public COORDINATOR;

    // Your subscription ID.
    // MUST be passed in constructor!
    uint64 public s_subscriptionId;

    // BSC coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 public keyHash;

    uint32 public callbackGasLimit = 100_069; // so funny..

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 12;

    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 public numWords = 1;

    uint256 public s_randomWord;
    uint256 public s_requestId;

    // For ticketing system
    uint256 public requestSubmitted;
    uint256 public nbTickets;
    uint256 public winningTicketPlusOne;

    constructor(uint64 subscriptionId, address vrfCoordinator_, bytes32 keyHash_) VRFConsumerBaseV2(vrfCoordinator_) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
        s_subscriptionId = subscriptionId;
        keyHash = keyHash_;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(uint256 nbTickets_) internal {
        requestSubmitted = block.number;
        nbTickets = nbTickets_;

        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        require(requestId == s_requestId, "stranger danger");
        s_randomWord = randomWords[0];
        uint256 winningTicket = randomWords[0] % nbTickets;

        // add one to know if initialized but later substract it
        winningTicketPlusOne = winningTicket + 1;
    }
}