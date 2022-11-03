// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFeedStrategy {
    function getPrice() external view returns (int256 value, uint8 decimals);
    function getPriceOfAmount(uint256 amount) external view returns (int256 value, uint8 decimals);
}