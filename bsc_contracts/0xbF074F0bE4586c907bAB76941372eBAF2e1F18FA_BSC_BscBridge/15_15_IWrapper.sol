// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IWrapper {
    event Deposit(address indexed dst, uint amount);
    event Withdrawal(address indexed src, uint amount);

    function deposit() external payable;

    function withdraw(uint amount) external;
}