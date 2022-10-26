// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenFactory {
    function createDToken(address logic, uint index) external returns (address tokenAddress);
    function computeTokenAddress(address logic, uint index) external view returns (address tokenAddress);
}