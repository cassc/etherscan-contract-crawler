// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWomDepositor {
    function deposit(uint256 _amount, address _stakeAddress) external returns (bool);
}