// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
}