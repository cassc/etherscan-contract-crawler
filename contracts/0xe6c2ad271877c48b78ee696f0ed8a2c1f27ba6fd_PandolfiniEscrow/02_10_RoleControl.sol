// contracts/RoleControl.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleControl is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    constructor(address root) {
        // NOTE: Other DEFAULT_ADMIN's can remove other admins, give this role with great care
        _setupRole(DEFAULT_ADMIN_ROLE, root); // The creator of the contract is the default admin
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        // SETUP role Hierarchy:
        // DEFAULT_ADMIN_ROLE > ADMIN_ROLE
        grantRole(ADMIN_ROLE, root);
        grantRole(OPERATOR_ROLE, root);
        grantRole(MINTER_ROLE, root);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to Admins.");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Restricted to Minter.");
        _;
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Restricted to OPERATORS.");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function isMinter(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function isOperator(address account) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    function addAdminRole(address account) public onlyAdmin {
        grantRole(ADMIN_ROLE, account);
        grantRole(OPERATOR_ROLE, account);
    }

    function addMinterRole(address account) public onlyAdmin {
        grantRole(MINTER_ROLE, account);
    }

    function addOperatorRole(address account) public onlyAdmin {
        grantRole(OPERATOR_ROLE, account);
    }

    function removeAdminRole(address account) public onlyAdmin {
        revokeRole(ADMIN_ROLE, account);
    }

    function removeMinterRole(address account) public onlyAdmin {
        revokeRole(MINTER_ROLE, account);
    }

    function removeOperatorRole(address account) public onlyAdmin {
        revokeRole(OPERATOR_ROLE, account);
    }
}