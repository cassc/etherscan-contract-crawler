//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReward {
    function mintTokens(address account, uint256[] calldata tokenIds) external;
}