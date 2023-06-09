// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IBasicRandcastConsumerBase {
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external;

    function rawFulfillRandomWords(bytes32 requestId, uint256[] memory randomWords) external;

    function rawFulfillShuffledArray(bytes32 requestId, uint256[] memory shuffledArray) external;
}