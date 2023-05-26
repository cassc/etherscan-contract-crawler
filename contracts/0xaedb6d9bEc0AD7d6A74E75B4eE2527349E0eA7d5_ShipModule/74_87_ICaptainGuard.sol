// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Actions open during the Crowdfund phase
interface ICaptainGuard {
    // When msg.sender is not a captain
    error NotCaptain();
    error ZeroAddressCaptain();

    /// @notice Assign a new captain
    /// @param captain The new address to assign as captain
    function updateCaptain(address captain) external;
}