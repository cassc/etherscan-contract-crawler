// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWomDepositor {
    function deposit(uint256, bool) external;

    event Deposited(address indexed _user, uint256 _amount);
}