// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "openzeppelin-upgradeable/access/Ownable2StepUpgradeable.sol";
import "openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title Safe Access Control
 * @author Trader Joe
 * @notice This contract extends OpenZeppelin's AccessControl and Ownable2Step contracts. It bounds the
 * `DEFAULT_ADMIN_ROLE` to the owner of the contract, and ensures that only the owner has it. The
 * `DEFAULT_ADMIN_ROLE` is transferred to the new owner when the owner changes.
 * It also adds a modifier that allows only the owner or the role admin to call a function.
 */
abstract contract SafeAccessControlUpgradeable is Ownable2StepUpgradeable, AccessControlUpgradeable {
    error SafeAccessControl__OnlyOwnerOrRole(bytes32 role);
    error SafeAccessControl__DefaultAdminRoleBoundToOwner();

    function __SafeAccessControl_init() internal onlyInitializing {
        __Ownable2Step_init();
        __AccessControl_init();
    }

    function __SafeAccessControl_init_unchained() internal onlyInitializing {}

    /**
     * @notice Modifier to chech that the caller is the owner or the role admin.
     */
    modifier onlyOwnerOrRole(bytes32 role) {
        if (owner() != msg.sender && !hasRole(role, msg.sender)) {
            revert SafeAccessControl__OnlyOwnerOrRole(role);
        }
        _;
    }

    /**
     * @notice Grant `role` to `account`.
     * @dev Needs to be called by the owner or the role admin.
     * @param role The role to grant.
     * @param account The account to grant the role to.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyOwnerOrRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @notice Revoke `role` from `account`.
     * @dev Needs to be called by the owner or the role admin.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyOwnerOrRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @notice Renounce `role` from the caller.
     * @dev Needs to be called by the account that has the role.
     * @param role The role to renounce.
     * @param account The account to renounce the role from.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
    }

    /**
     * @dev Transfer ownership of the contract and the `DEFAULT_ADMIN_ROLE` role to `newOwner`.
     * @param newOwner The address of the new owner.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        address previousOwner = owner();
        super._transferOwnership(newOwner);

        _revokeRole(DEFAULT_ADMIN_ROLE, previousOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    }

    /**
     * @dev Grant `role` to `account`. If the role to grant is the `DEFAULT_ADMIN_ROLE`, ensure that the account
     * that receives it is the current owner of the contract. If not, revert.
     * @param role The role to grant.
     * @param account The account to grant the role to.
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        if (role == DEFAULT_ADMIN_ROLE && account != owner()) {
            revert SafeAccessControl__DefaultAdminRoleBoundToOwner();
        }

        super._grantRole(role, account);
    }

    /**
     * @dev Revoke `role` from `account`. If the role to revoke is the `DEFAULT_ADMIN_ROLE`, ensure that the account
     * that loses it is not the current owner of the contract. If not, revert.
     * @param role The role to revoke.
     * @param account The account to revoke the role from.
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        if (role == DEFAULT_ADMIN_ROLE && account == owner()) {
            revert SafeAccessControl__DefaultAdminRoleBoundToOwner();
        }

        super._revokeRole(role, account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}