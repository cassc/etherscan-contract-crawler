// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IRandomizer {
    // Returns a request ID for the random number. This should be kept and mapped to whatever the contract
    // is tracking randoms for.
    // Admin only.
    function getRandomNumber() external returns(bytes32);

    function random(uint256 _tokenId) external returns(uint256);
}