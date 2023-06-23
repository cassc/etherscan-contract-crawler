// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterVault_V2 {

    // --- Events ---
    event Claim(address indexed owner, address indexed receiver, uint256 yield);
    event Provider(address oldProvider, address newProvider);
    event YieldHeritor(address oldHeritor, address newHeritor);
    event YieldMargin(uint256 oldMargin, uint256 newMargin);
    event AdapterChanged(address oldAdapter, address newAdapter);
}