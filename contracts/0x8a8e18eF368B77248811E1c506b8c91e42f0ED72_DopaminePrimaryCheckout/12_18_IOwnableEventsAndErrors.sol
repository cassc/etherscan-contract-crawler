// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Ownable Events & Errors Interface
interface IOwnableEventsAndErrors {

    /// @notice Emits when a new pending owner is set.
    /// @param pendingOwner The address of the new pending owner.
    event PendingOwnerSet(
        address indexed pendingOwner
    );

    /// @notice Caller is not the owner of the contract.
    error OwnerOnly();

    /// @notice The pending owner is invalid.
    error PendingOwnerInvalid();

    /// @notice Caller is not the pending owner of the contract.
    error PendingOwnerOnly();

    /// @notice The pending owner is already set to the specified address.
    error PendingOwnerAlreadySet();

}