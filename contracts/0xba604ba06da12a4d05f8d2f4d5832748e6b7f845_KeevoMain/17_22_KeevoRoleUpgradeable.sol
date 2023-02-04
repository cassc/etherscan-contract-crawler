// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./AccessControlUpgradeable.sol";

/**
 * @title KeevoRole contract
 * @author BloxiCo
 * @dev This contract is used for role control of other contracts
 * - There is 2 roles presented:
 *   # ADMIN
 *   # MINTER
 * - ADMIN role can add (setup) or remove (revoke) all roles passing address
 * - for every role there is modifier defined that is used in function calls
 **/
contract KeevoRoleUpgradeable is AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Ownable: caller is not the admin");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "Ownable: caller is not the minter");
        _;
    }

    /**
     * @dev sender address is owner of the contract and gets ADMIN role
     **/
    function __KeevoRoleUpgradeable_init_unchained() internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Function can be called by Admin only.
     * Adds MINTER role to the address
     * @param _account The address that should get MINTER role
     **/
    function addMinter(address _account) public onlyAdmin {
        _setupRole(MINTER_ROLE, _account);
    }

    /**
     * @dev Function can be called by Admin only.
     * Removes MINTER role from the address
     * @param _account The address that should be revoked from MINTER role
     **/
    function removeMinter(address _account) public onlyAdmin {
        revokeRole(MINTER_ROLE, _account);
    }

    /**
     * @dev Function can be called by Admin only.
     * Adds ADMIN role to the address
     * @param _account The address that should get ADMIN role
     **/
    function addAdmin(address _account) public onlyAdmin {
        _setupRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /**
     * @dev Function can be called by Admin only.
     * Removes ADMIN role from the address
     * @param _account The address that should be revoked from ADMIN role
     **/
    function removeAdmin(address _account) public onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, _account);
    }

    function isMinter(address _account) internal view virtual returns (bool) {
        return hasRole(MINTER_ROLE, _account);
    }

    function isAdmin(address _account) internal view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }
}
