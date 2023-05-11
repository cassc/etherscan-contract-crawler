// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

interface IStakingToken {
    function stake(uint256 amount) external returns (bool success);
    function unstake(uint256 amount) external returns (bool success);
}