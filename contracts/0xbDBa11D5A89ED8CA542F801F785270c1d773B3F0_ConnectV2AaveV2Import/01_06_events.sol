//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Events {
    event LogAaveV2Import(
        address indexed user,
        bool convertStable,
        address[] supplyTokens,
        address[] borrowTokens,
        uint[] supplyAmts,
        uint[] stableBorrowAmts,
        uint[] variableBorrowAmts
    );
}