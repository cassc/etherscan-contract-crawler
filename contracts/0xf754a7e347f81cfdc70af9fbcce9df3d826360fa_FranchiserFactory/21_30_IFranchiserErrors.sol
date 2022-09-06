// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

/// @title Errors thrown by the Franchiser contract.
interface IFranchiserErrors {
    /// @notice Thrown when an address other than the `delegatee` attempts to call a
    ///         function restricted to the `delegatee`.
    /// @param caller The address that attempted the call.
    /// @param delegatee The `delegatee`.
    error NotDelegatee(address caller, address delegatee);

    /// @notice Thrown when attempting to initialize an OwnedDelegator contract with
    ///         a `delegatee` address of 0.
    error NoDelegatee();

    /// @notice Thrown when attempting to set the `delegatee` more than once.
    error AlreadyInitialized();

    /// @notice Thrown when attempting to add too many `subDelegatees`.
    /// @param maximumSubDelegatees The maximum (and current) number of `subDelegatees`.
    error CannotExceedMaximumSubDelegatees(uint256 maximumSubDelegatees);

    /// @notice Emitted when two array arguments have different cardinalities.
    /// @param length0 The length of the first array argument.
    /// @param length1 The length of the second array argument.
    error ArrayLengthMismatch(uint256 length0, uint256 length1);
}