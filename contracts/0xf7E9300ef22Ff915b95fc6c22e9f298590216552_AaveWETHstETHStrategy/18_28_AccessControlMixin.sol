// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.9.0;

import "./IAccessControlProxy.sol";

/// @title AccessControlMixin
/// @dev AccessControlMixin contract that allows children to implement multi-role-based access control mechanisms.
/// @author Bank of Chain Protocol Inc
abstract contract AccessControlMixin {
    IAccessControlProxy public accessControlProxy;

    function _initAccessControl(address _accessControlProxy) internal {
        accessControlProxy = IAccessControlProxy(_accessControlProxy);
    }

    /// @dev Modifier that checks that `_account has `_role`. 
    /// Revert with a standard message if `_account` is missing `_role`.
    modifier hasRole(bytes32 _role, address _account) {
        accessControlProxy.checkRole(_role, _account);
        _;
    }

    /// @dev Modifier that checks that msg.sender has a specific role. 
    /// Reverts  with a standardized message including the required role.
    modifier onlyRole(bytes32 _role) {
        accessControlProxy.checkRole(_role, msg.sender);
        _;
    }

    /// @dev Modifier that checks that msg.sender has a default admin role or delegate role. 
    /// Reverts  with a standardized message including the required role.
    modifier onlyGovOrDelegate() {
        accessControlProxy.checkGovOrDelegate(msg.sender);
        _;
    }

    /// @dev Modifier that checks that msg.sender is the vault manager or not
    modifier isVaultManager() {
        accessControlProxy.checkVaultOrGov(msg.sender);
        _;
    }

    /// @dev Modifier that checks that msg.sender has a keeper role or not
    modifier isKeeper() {
        accessControlProxy.checkKeeperOrVaultOrGov(msg.sender);
        _;
    }
}