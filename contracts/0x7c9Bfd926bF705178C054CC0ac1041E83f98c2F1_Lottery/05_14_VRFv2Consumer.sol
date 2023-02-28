// SPDX-License-Identifier: MIT

pragma solidity =0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract VRFv2Consumer is VRFConsumerBaseV2, Initializable {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    // address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    // bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 internal constant callbackGasLimit = 100000;

    address internal vrfCoordinator;

    bytes32 internal keyHash;

    // The default is 3, but you can set this higher.
    uint16 internal constant requestConfirmations = 3;

    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 internal constant numWords = 1;

    uint256[] internal s_randomWords;
    uint256 public s_requestId;
    address internal s_owner;
    bool internal isInitialized;

    function initializeV2Consumer(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    ) internal  {
        require(!isInitialized, "Already Initialized");
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        setCoordinator(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = _subscriptionId;
        isInitialized = true;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal returns (uint256) {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        return s_requestId;
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal virtual override {
        s_randomWords = randomWords;
    }
}