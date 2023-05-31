// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Actions for revenue claims
interface IClaimActions {
    /// @notice Get the amount claimable at an event
    /// @param account The address to get claim amount
    /// @param claimID The claim event ID to claim revenue
    /// @return The amount claimed
    function getClaimAmount(
        address account,
        uint256 claimID
    ) external view returns (uint256);

    /// @notice Check if an address has claims at an event
    /// @param account The address to check
    /// @param claimID The claim event ID to check for claim revenue
    /// @return True of address has claim
    function hasClaim(
        address account,
        uint256 claimID
    ) external view returns (bool);

    /// @notice Claim revenue at for a particular event
    /// @param claimID The claim event ID to claim revenue
    /// @return The amount claimed
    function claim(uint256 claimID) external returns (uint256);

    // Make this receive eth
    receive() external payable;
}