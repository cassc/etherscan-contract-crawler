// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IHoarderRewards {
    function setBalance(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external;
}