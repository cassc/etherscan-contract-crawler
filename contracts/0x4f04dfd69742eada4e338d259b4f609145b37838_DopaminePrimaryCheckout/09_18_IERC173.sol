// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IERC173EventsAndErrors} from "./IERC173EventsAndErrors.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title IERC173 Interface
interface IERC173 is IERC165, IERC173EventsAndErrors {

    /// @notice Get the owner address of the contract.
    /// @return The address of the owner.
    function owner() view external returns(address);

    /// @notice Set the new owner address of the contract.
    function transferOwnership(address newOwner) external;

}