// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOKXFootballCup {
    function totalSupply() external returns (uint256);

    function totalSupply(uint256) external returns (uint256);

    function balanceOf(address, uint256) external returns (uint256);
}