// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {Owned} from "solmate/auth/Owned.sol";
import {AddressHelper} from "src/libraries/AddressHelper.sol";
import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// @notice Claim all rewards for a given platform.
abstract contract Auth is Owned {
    /// @notice Throwed the caller is not an approved manager.
    error NOT_ALLOWED_MANAGER();

    /// @notice Addresses of the approved managers.
    mapping(address => bool) public allowListManagers;

    ////////////////////////////////////////////////////////////////
    /// --- EVENTS
    ///////////////////////////////////////////////////////////////

    /// @notice Emitted when a manager is approved.
    /// @param manager The address of the manager.
    event ManagerAllowed(address indexed manager);

    /// @notice Emitted when a manager is disowned.
    /// @param manager The address of the manager.
    event ManagerDisowned(address indexed manager);

    modifier onlyAllowed() {
        if (!allowListManagers[msg.sender]) revert NOT_ALLOWED_MANAGER();
        _;
    }

    constructor(address _owner) Owned(_owner) {
        allowListManagers[_owner] = true;
    }

    /// @notice Approve a manager.
    /// @param _manager The manager to approve.
    function approveManager(address _manager) external onlyOwner {
        allowListManagers[_manager] = true;
        emit ManagerAllowed(_manager);
    }

    /// @notice Disown a manager.
    /// @param _manager The manager to disown.
    function disownManager(address _manager) external onlyOwner {
        allowListManagers[_manager] = false;
        emit ManagerDisowned(_manager);
    }
}