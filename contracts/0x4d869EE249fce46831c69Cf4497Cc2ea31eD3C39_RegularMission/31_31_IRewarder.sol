// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IRewarder {
    function reward(address to, uint256 amount) external;
}