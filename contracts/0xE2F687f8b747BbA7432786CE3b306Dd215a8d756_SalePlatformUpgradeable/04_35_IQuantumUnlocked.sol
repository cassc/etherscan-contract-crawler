// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuantumUnlocked {
    function dropSupply(uint128 dropId) external returns (uint128);

    function mint(
        address to,
        uint128 dropId,
        uint256 variant
    ) external returns (uint256);
}