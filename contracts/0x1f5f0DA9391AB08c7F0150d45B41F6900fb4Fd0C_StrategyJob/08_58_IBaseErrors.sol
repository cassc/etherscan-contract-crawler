// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

interface IBaseErrors {
    /// @notice Thrown if an address is invalid
    error InvalidAddress();

    /// @notice Thrown if an amount is invalid
    error InvalidAmount();

    /// @notice Thrown if the lengths of a set of lists mismatch
    error LengthMismatch();

    /// @notice Thrown if an address is the zero address
    error ZeroAddress();

    /// @notice Thrown if an amount is zero
    error ZeroAmount();
}