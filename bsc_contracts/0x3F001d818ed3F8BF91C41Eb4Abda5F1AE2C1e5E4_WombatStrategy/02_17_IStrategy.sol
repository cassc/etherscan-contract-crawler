// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IStrategy {
    function deposit() external payable;

    function withdraw(uint256 _amount) external returns (uint256);

    function harvest() external returns (uint256);

    event Deposit(address indexed _address, uint256 _amount);
    event Withdraw(address indexed _address, uint256 _amount);
    event Harvest();
    event SetRewards(address indexed _address);
    event DepositRewards(address indexed _address, uint256 _amount);
}