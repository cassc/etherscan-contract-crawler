// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IEuler {
    function deposit(uint256, uint256) external; // void

    function withdraw(uint256, uint256) external; // void
}