// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { IAccessControlManager } from "interfaces/IAccessControlManager.sol";

import "../utils/Errors.sol";

/// @title AccessControl
/// @author Angle Labs, Inc.
contract AccessControl {
    /// @notice `accessControlManager` used to check roles
    IAccessControlManager public accessControlManager;

    uint256[49] private __gapAccessControl;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                       MODIFIERS                                                    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether the `msg.sender` has the governor role
    modifier onlyGovernor() {
        if (!accessControlManager.isGovernor(msg.sender)) revert NotGovernor();
        _;
    }

    /// @notice Checks whether the `msg.sender` has the guardian role
    modifier onlyGuardian() {
        if (!accessControlManager.isGovernorOrGuardian(msg.sender)) revert NotGovernorOrGuardian();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                       FUNCTIONS                                                    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether `admin` has the governor role
    function isGovernor(address admin) external view returns (bool) {
        return accessControlManager.isGovernor(admin);
    }

    /// @notice Checks whether `admin` has the guardian role
    function isGovernorOrGuardian(address admin) external view returns (bool) {
        return accessControlManager.isGovernorOrGuardian(admin);
    }
}