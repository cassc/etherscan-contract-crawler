// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRLand {
    function getTokenId(uint256 x, uint256 y) external view returns (uint256);
}