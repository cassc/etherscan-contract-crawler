// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract VRFIntegration is Ownable, VRFConsumerBaseV2 {
    error RandomSeedAlreadySettled();

    event RandomSeedSettled(uint256 requestId, uint256 seed);
    event RandomSeedManuallySettled(uint256 seed);

    VRFCoordinatorV2Interface public immutable vrfCoordinator;
    uint64 public immutable vrfSubscriptionId;
    bytes32 public immutable vrfKeyHash;
    uint32 public vrfCallbackGasLimit = 200000;
    bool public randomSeedSettled = false;
    uint256 public randomSeed;

    /**
     * @notice Constructor
     * @param coordinator chainlink VRF coordinator contract address
     * @param keyHash chainlink VRF key hash
     * @param subscriptionId chainlink VRF subscription id
     */
    constructor(
        address coordinator,
        bytes32 keyHash,
        uint64 subscriptionId
    ) VRFConsumerBaseV2(coordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(coordinator);
        vrfSubscriptionId = subscriptionId;
        vrfKeyHash = keyHash;
    }

    /**a
     * @notice Implemention of VRFConsumerBaseV2, only be called by vrf coordinator
     * @param requestId vrf request id
     * @param randomWords result from vrf
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        if (!randomSeedSettled) {
            randomSeedSettled = true;
            uint256 seed = randomWords[0];
            randomSeed = seed;
            emit RandomSeedSettled(requestId, seed);
            afterRandomSeedSettled(seed);
        }
    }

    /**
     * @notice Make a request to chainlink VRF to generate a random word
     */
    function requestRandomWords() external onlyOwner {
        if (randomSeedSettled) {
            revert RandomSeedAlreadySettled();
        }
        uint16 requestConfirmations = 3;
        uint16 numWords = 1;
        vrfCoordinator.requestRandomWords(
            vrfKeyHash,
            vrfSubscriptionId,
            requestConfirmations,
            vrfCallbackGasLimit,
            numWords
        );
    }

    /**
     * @notice Allow issuer to set random seed manually
     * Dealing with unforeseen circumstances, under community supervision
     * @param seed random number
     */
    function emergencySetRandomSeed(uint256 seed) external onlyOwner {
        randomSeedSettled = true;
        randomSeed = seed;
        emit RandomSeedManuallySettled(seed);
        afterRandomSeedSettled(seed);
    }

    /**
     * @notice Set VRF callback gas limit in case the default is insufficient
     * @param gasLimit gas limit
     */
    function setVRFCallbackGasLimit(uint32 gasLimit) external onlyOwner {
        vrfCallbackGasLimit = gasLimit;
    }

    function afterRandomSeedSettled(uint256 seed) internal virtual {}
}