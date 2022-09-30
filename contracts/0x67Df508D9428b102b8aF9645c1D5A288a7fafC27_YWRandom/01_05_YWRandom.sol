// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract YWRandom is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface m_coordinator;
    uint256 private constant REQUEST_IN_PROGRESS = 42;

    // Mainnet coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    // This is the 200 GWEI Gas lane
    bytes32 s_keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    
    uint32 callbackGasLimit = 40000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    uint64 m_subscriptionId;

    mapping(uint256 => address) private m_requests;
    mapping(address => uint256) private m_results;

    event RequestLaunched(uint256 indexed requestId, address indexed msgsender);
    event RequestLanded(uint256 indexed requestId, uint256 indexed result);
    event ResultSelected(address indexed msgsender, uint256 result);

    // constructor
    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        m_coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        m_subscriptionId = subscriptionId;
    }

    function setSubscriptionId(uint64 subscriptionId) public onlyOwner {
        m_subscriptionId = subscriptionId;
    }

    function requestRandomness() public onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = m_coordinator.requestRandomWords(
            s_keyHash,
            m_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        m_requests[requestId] = msg.sender;
        m_results[msg.sender] = REQUEST_IN_PROGRESS;
        emit RequestLaunched(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        m_results[m_requests[requestId]] = randomWords[0];
        emit RequestLanded(requestId, randomWords[0]);
    }

    function pickWinner(uint256[][] memory ranges) public onlyOwner returns (uint256) {
        require(m_results[msg.sender] != 0 && m_results[msg.sender] != REQUEST_IN_PROGRESS, "Randomness must be requested before picking a winner");
        uint256 randomness = m_results[msg.sender];
        uint256 rangeIndex = (randomness % ranges.length) + 1;
        uint256 winner = randomness % (ranges[rangeIndex][1] - ranges[rangeIndex][0] + 1) + ranges[rangeIndex][0];

        emit ResultSelected(msg.sender, winner);
        return winner;
    }

}