// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract BtnRandom8 is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    event BtnRandom8__RandomResult(
        uint256 indexed requestId,
        uint256 indexed idx,
        uint256 indexed tokenId,
        uint256 randomword
    );

    event BtnRandom8__RandomRequested(uint256 indexed requestId);

    // Your subscription ID.
    uint64 public immutable s_subscriptionId;

    // address constant vrfCoordinator =
    //     0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D; // Goerli
    // bytes32 constant keyHash =
    //     0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15; // Goerli

    address constant vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909; // Mainnet
    bytes32 constant keyHash =
        0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92; // Mainnet

    // Adjust to (20,000 * numwords) + (event * 10,000 )
    uint32 constant callbackGasLimit = 750000;
    uint16 constant requestConfirmations = 3;

    uint32 constant numWords = 24;
    uint256 constant NO_OF_TOKEN = 2105 - 1 + 1;
    uint256 constant TOKEN_START = 1;

    // uint256[] public s_randomWords;
    uint256 public s_requestId;
    address public immutable s_owner;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    function requestRandomWords() external onlyOwner {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit BtnRandom8__RandomRequested(s_requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // s_randomWords = randomWords;

        for (uint i = 0; i < randomWords.length; i++) {
            uint256 tokenId = (randomWords[i] % NO_OF_TOKEN) + TOKEN_START;
            emit BtnRandom8__RandomResult(
                requestId,
                i,
                tokenId,
                randomWords[i]
            );
        }
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}