// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    function rebase() external;
    function stake(uint256) external;
    function unstake(uint256) external;
    function index() external view returns (uint256);
}