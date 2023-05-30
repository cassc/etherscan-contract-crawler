// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IAMTManager {
    function amt(address user) external view returns (uint256);

    function add(address to, uint256 value) external;

    function use(address from, uint256 value, string calldata action) external;
}