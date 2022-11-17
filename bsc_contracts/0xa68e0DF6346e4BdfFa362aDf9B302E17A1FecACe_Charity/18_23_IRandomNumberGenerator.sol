//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 lotteryId) external returns (bytes32 requestId);
}