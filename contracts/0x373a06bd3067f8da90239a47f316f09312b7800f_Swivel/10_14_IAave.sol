// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IAave {
    function deposit(
        address,
        uint256,
        address,
        uint16
    ) external; // void

    function withdraw(
        address,
        uint256,
        address
    ) external returns (uint256);
}