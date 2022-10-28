// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IDepositor {
    function deposit(uint256 _amount, bool _lock) external;
}