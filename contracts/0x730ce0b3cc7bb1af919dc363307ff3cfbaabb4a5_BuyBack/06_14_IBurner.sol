// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

/// Gro burner interface - used to move gro tokens into the vesting contract
interface IBurner {
    function reVest(uint256 amount) external;
}