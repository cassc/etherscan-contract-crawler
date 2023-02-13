// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFxsDepositor {
   function deposit(uint256 _amount, bool _lock) external;
}