// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// @title IInitializable
// @author Rohan Kulkarni
// @notice The external Initializable events and errors
// @notice repo github.com/ourzora/nouns-protocol
interface IInitializable {
    /// @notice Emitted when the contract has been initialized or reinitialized
    event Initialized(uint256 version);

    /// @dev Reverts if incorrectly initialized with address(0)
    error ADDRESS_ZERO();

    /// @dev Reverts if disabling initializers during initialization
    error INITIALIZING();

    /// @dev Reverts if calling an initialization function outside of initialization
    error NOT_INITIALIZING();

    /// @dev Reverts if reinitializing incorrectly
    error ALREADY_INITIALIZED();
}