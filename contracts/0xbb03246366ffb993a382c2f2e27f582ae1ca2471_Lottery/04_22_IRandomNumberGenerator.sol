//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomNumberGenerator {
    /**
     * Requests randomness for a given lottery id
     */
    function requestRandomWords(uint256 lotteryId)
        external
        returns (uint256 requestId);
}