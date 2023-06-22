// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPirateMetadata {
    function getTribeForPirate(uint8) external view returns (uint256);
    function getCountForTribe(uint8) external view returns (uint256);
}