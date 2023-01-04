// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICommonErrors {
    /// @notice The provided address is the zero address.
    error ZeroAddress();
    /// @notice The attempted action is not allowed.
    error Forbidden();
    /// @notice The requested entity cannot be found.
    error NotFound();
}