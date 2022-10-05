// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICharity {
    function addToCharity(uint256 amount, address user) external; 

    function swapNow() external;
}