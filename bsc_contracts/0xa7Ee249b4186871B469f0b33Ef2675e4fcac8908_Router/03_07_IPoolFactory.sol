// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolFactory {
    function createPool(address logic_) external returns (address poolAddress);
    function computePoolAddress(address logic) external view returns (address poolAddress);
    function getFeeInfo() external returns (address recipient, uint num, uint denom);
}