// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Events for crowdfund phase
interface ICrowdfundEvents {
    /// @notice When the minimum raise is met
    event RaiseMet();

    /// @notice When the captain or authorized 3rd party (eg: SZNS DAO) closes the ship before the sail raise duration
    event ForceEndRaise();

    /// @notice When the minimum raise is met
    /// @param contributor Address that contributed
    /// @param amount Amount contributed
    event Contributed(address indexed contributor, uint256 amount);
}