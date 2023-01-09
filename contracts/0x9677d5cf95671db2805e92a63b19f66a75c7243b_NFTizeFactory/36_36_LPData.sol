// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

struct LPData {
    address depositor;
    address lpTokenAddress;
    uint256 theosTokenAmount;
    uint256 indexPoolTokenAmount;
    address lpManagerAddress;
}