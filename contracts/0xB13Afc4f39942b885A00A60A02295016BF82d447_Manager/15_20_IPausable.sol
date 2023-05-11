// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// @title IPausable
// @author Rohan Kulkarni
// @notice The external Pausable events, errors, and functions
// @custom:mod repo github.com/ourzora/nouns-protocol
interface IPausable {
    /// @notice Emitted when the contract is paused
    /// @param user The address that paused the contract
    event Paused(address user);

    /// @notice Emitted when the contract is unpaused
    /// @param user The address that unpaused the contract
    event Unpaused(address user);

    /// @dev Reverts if called when the contract is paused
    error PAUSED();

    /// @dev Reverts if called when the contract is unpaused
    error UNPAUSED();

    /// @notice If the contract is paused
    function paused() external view returns (bool);

    /// @notice Pauses the contract
    function pause() external;
}