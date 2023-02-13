// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPool {
    function distributeReward(uint256 value) external;
}