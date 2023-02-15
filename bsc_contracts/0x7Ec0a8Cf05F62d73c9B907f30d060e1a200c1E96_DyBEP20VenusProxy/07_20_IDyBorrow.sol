// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IDyBNBBorrow {
    function deposit(
        uint256 amount_,
        address depositor_,
        address underlying_
    ) external payable;

    function withdraw(
        uint256,
        address withdrawer_,
        address underlying_
    ) external;
}