// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZunamiStrategy {
    function deposit(uint256[3] memory amounts) external returns (uint256);
}