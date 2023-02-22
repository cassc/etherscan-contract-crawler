// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title IERC173 Events & Errors Interface
interface IERC173Events {

    /// @notice Emits when ownership is transferred to another address.
    /// @param previousOwner The address of the prior owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

}