// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuantumArtSeeder {
    function dropIdToSeed(uint256 dropId) view external returns (uint256);
}