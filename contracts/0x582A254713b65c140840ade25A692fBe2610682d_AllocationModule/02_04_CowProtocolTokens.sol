// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

/// @dev Interface exposing some of the functions of the governance token for the CoW Protocol.
/// @title CoW Protocol Governance Token Minimal Interface
/// @author CoW Protocol Developers
interface CowProtocolToken {
    /// @dev Moves `amount` tokens from the caller's account to `to`.
    /// Returns true. Reverts if the operation didn't succeed.
    function transfer(address to, uint256 amount) external returns (bool);
}

/// @dev Interface exposing some of the functions of the virtual token for the CoW Protocol.
/// @title CoW Protocol Virtual Token Minimal Interface
/// @author CoW Protocol Developers
interface CowProtocolVirtualToken {
    /// @dev Converts an amount of (virtual) tokens from this contract to real
    /// tokens based on the claims previously performed by the caller.
    /// @param amount How many virtual tokens to convert into real tokens.
    function swap(uint256 amount) external;

    /// @dev Address of the real COW token. Tokens claimed by this contract can
    /// be converted to this token if this contract stores some balance of it.
    function cowToken() external view returns (address);
}