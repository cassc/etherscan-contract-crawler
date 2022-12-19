//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Group managment interface
/// @author Amit Molek
interface IGroup {
    /// @dev Emitted when a member joins the group
    /// @param account the member that joined the group
    /// @param ownershipUnits number of ownership units bought
    event Joined(address account, uint256 ownershipUnits);

    /// @dev Emitted when a member acquires more ownership units
    /// @param account the member that acquired more
    /// @param ownershipUnits number of ownership units bought
    event AcquiredMore(address account, uint256 ownershipUnits);

    /// @dev Emitted when a member leaves the group
    /// @param account the member that leaved the group
    event Left(address account);

    /// @notice Join the group
    /// @dev The caller must pass contribution to the group
    /// which also represent the ownership units.
    /// The value passed to this function MUST include:
    /// the ownership units cost, Antic fee and deployment cost refund
    /// (ownership units + Antic fee + deployment refund)
    /// Emits `Joined` event
    function join(bytes memory data) external payable;

    /// @notice Acquire more ownership units
    /// @dev The caller must pass contribution to the group
    /// which also represent the ownership units.
    /// The value passed to this function MUST include:
    /// the ownership units cost, Antic fee and deployment cost refund
    /// (ownership units + Antic fee + deployment refund)
    /// Emits `AcquiredMore` event
    function acquireMore(bytes memory data) external payable;

    /// @notice Leave the group
    /// @dev The member will be refunded with his join contribution and Antic fee
    /// Emits `Leaved` event
    function leave() external;
}