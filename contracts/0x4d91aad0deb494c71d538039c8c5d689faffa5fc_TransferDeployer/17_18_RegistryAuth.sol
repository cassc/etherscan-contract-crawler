//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {Auth, Authority} from "./lib/auth/Auth.sol";
import {RolesAuthority} from "./lib/auth/authorities/RolesAuthority.sol";

// --- Errors ---
error OwnershipInvalid();

/**
 * @notice RegistryAuth - contract to control ownership of the Registry.
 */
contract RegistryAuth is RolesAuthority {
    /// @notice Emitted when the first step of an ownership transfer (proposal) is done.
    event OwnershipTransferProposed(address indexed user, address indexed newOwner);

    /// @notice Emitted when the second step of an ownership transfer (claim) is done.
    event OwnershipChanged(address indexed owner, address indexed newOwner);

    // --- Storage ---
    /// @notice Pending owner for 2 step ownership transfer
    address public pendingOwner;

    // --- Constructor ---
    constructor(address _owner, Authority _authority) RolesAuthority(_owner, _authority) {}

    /**
     * @notice Starts the 2 step process of transferring registry authorization to a new owner.
     * @param _newOwner Proposed new owner of registry authorization.
     */
    function transferOwnership(address _newOwner) external requiresAuth {
        pendingOwner = _newOwner;

        emit OwnershipTransferProposed(msg.sender, _newOwner);
    }

    /**
     * @notice Completes the 2 step process of transferring registry authorization to a new owner.
     * This function must be called by the proposed new owner.
     */
    function claimOwnership() external {
        if (msg.sender != pendingOwner) revert OwnershipInvalid();
        emit OwnershipChanged(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    /**
     * @notice Old approach of setting a new owner in a single step.
     * @dev This function throws an error to force use of the new 2-step approach.
     */
    function setOwner(address /*newOwner*/ ) public view override requiresAuth {
        revert OwnershipInvalid();
    }
}