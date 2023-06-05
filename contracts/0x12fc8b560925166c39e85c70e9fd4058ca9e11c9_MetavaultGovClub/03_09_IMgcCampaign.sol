// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IMgcCampaign {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
}