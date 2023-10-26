// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/access/OwnablePermissions.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

abstract contract AccessControlledMinters is OwnablePermissions, AccessControlEnumerable {

    error AccessControlledMinters__CallerDoesNotHaveAdminRole();
    error AccessControlledMinters__CannotTransferAdminRoleToSelf();
    error AccessControlledMinters__CannotTransferAdminRoleToZeroAddress();

    /// @notice Value defining the `Minter Role`.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /** 
     * @notice Allows the current contract admin to transfer the `Admin Role` to a new address.
     * @dev    Throws if newAdmin is the zero-address
     * @dev    Throws if the caller is not the current admin.
     * @dev    Throws if the caller is an admin and tries to transfer admin to itself.
     *
     * @dev <h4>Postconditions:</h4>
     * @dev 1. The caller/former admin has had `Admin Role` revoked.
     * @dev 2. The new admin has been granted the `Admin Role`.
     */
    function transferAdminRole(address newAdmin) external {
        _requireCallerIsAdmin();

        if(newAdmin == address(0)) {
            revert AccessControlledMinters__CannotTransferAdminRoleToZeroAddress();
        }

        if(newAdmin == _msgSender()) {
            revert AccessControlledMinters__CannotTransferAdminRoleToSelf();
        }

        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    /** 
     * @dev Validates that the caller is an admin
     * @dev Throws when the caller is not an admin
     */
    function _requireCallerIsAdmin() internal view {
        if(!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert AccessControlledMinters__CallerDoesNotHaveAdminRole();
        }
    }

    /**
     * @dev Validates that the caller is the contract owner or has been granted minter role
     * @dev Throws when the caller is not the contract owner and has not been granted minter role
     */
    function _requireCallerIsAllowedToMint() internal view {
        if(!hasRole(MINTER_ROLE, _msgSender())) {
            _requireCallerIsContractOwner();
        }
    }
}

abstract contract AccessControlledMintersInitializable is AccessControlledMinters {
    error AccessControlledMintersInitializable__AdminAlreadyInitialized();

    bool private _adminInitialized;

    /// @dev Initializes access control enumerable default admin.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeAdmin(address admin) public {
        _requireCallerIsContractOwner();

        if(_adminInitialized) {
            revert AccessControlledMintersInitializable__AdminAlreadyInitialized();
        }

        _adminInitialized = true;

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }
}