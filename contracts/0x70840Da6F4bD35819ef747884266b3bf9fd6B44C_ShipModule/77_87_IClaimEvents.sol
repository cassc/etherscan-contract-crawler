// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Actions that the ship can take
interface IClaimEvents {
    // When a user claims their share
    event Claimed(address account, uint256 amount, uint256 claimID);

    // Wben a new claim is available
    event Claimable(uint256 amount, uint256 claimID);
}