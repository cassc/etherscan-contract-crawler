// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Administered
 * @notice Implements Admin and User roles.
 */
contract Administered is AccessControl {
    bytes32 public constant USER_ROLE = keccak256("USER");

    /// @dev Add `root` to the admin role as a member.
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(USER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Restricted to admins.");
        _;
    }
    /// @dev Restricted to members of the user role.
    modifier onlyUser() {
        require(isUser(_msgSender()), "Restricted to users.");
        _;
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the user role.
    function isUser(address account) public view virtual returns (bool) {
        return hasRole(USER_ROLE, account);
    }

    /// @dev Add an account to the user role. Restricted to admins.
    function addUser(address account) public virtual onlyAdmin {
        grantRole(USER_ROLE, account);
    }

    /// @dev Add an account to the admin role. Restricted to admins.
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Remove an account from the user role. Restricted to admins.
    function removeUser(address account) public virtual onlyAdmin {
        revokeRole(USER_ROLE, account);
    }

    /// @dev Remove oneself from the admin role.
    function renounceAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
}