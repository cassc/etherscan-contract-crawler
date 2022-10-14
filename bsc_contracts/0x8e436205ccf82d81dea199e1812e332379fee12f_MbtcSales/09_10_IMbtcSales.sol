// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IMbtcSales {
    function getSellPrice() external view returns (uint256);
}