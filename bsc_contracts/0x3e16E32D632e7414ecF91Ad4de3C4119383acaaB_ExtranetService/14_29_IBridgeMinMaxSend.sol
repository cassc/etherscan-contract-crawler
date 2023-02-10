// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

interface IBridgeMinMaxSend {
    function minSend(address token) external view returns (uint256);
    function maxSend(address token) external view returns (uint256);
}