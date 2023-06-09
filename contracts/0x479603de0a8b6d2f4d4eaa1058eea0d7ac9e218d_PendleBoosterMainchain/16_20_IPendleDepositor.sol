// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPendleDepositor {
    function deposit(uint256, bool) external;

    event Deposited(address indexed _user, uint256 _amount);
}