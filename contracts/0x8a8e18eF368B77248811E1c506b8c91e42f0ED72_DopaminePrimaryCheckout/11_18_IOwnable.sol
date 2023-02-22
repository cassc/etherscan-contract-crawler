// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IERC173} from "./IERC173.sol";
import {IOwnableEventsAndErrors} from "./IOwnableEventsAndErrors.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Ownable Interface
interface IOwnable is IERC173, IOwnableEventsAndErrors {

    /// @notice Gets the pending owner of the contract.
    /// @return The pending owner address for the contract.
    function pendingOwner() external returns(address);

    /// @notice Sets the pending owner address for the contract.
    /// @param pendingOwner The address of the new pending owner.
    function setPendingOwner(address pendingOwner) external;

    /// @notice Permanently renounces contract ownership.
    function renounceOwnership() external;

}