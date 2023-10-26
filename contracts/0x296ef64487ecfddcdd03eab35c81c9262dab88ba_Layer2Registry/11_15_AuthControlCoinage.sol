//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AuthRoleCoinage.sol";

contract AuthControlCoinage is AuthRoleCoinage, ERC165Storage, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender), "AuthControl: Caller is not an admin");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "AuthControl: Caller is not a minter");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "AuthControl: Caller is not an operator");
        _;
    }


    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyOwner {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function addMinter(address account) public virtual onlyOwner {
        grantRole(MINTER_ROLE, account);
    }

    function addOperator(address account) public virtual onlyOwner {
        grantRole(OPERATOR_ROLE, account);
    }

    /// @dev remove admin
    /// @param account  address to remove
    function removeAdmin(address account) public virtual onlyOwner {
        renounceRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeMinter(address account) public virtual onlyOwner {
        renounceRole(MINTER_ROLE, account);
    }

    function removeOperator(address account) public virtual onlyOwner {
        renounceRole(OPERATOR_ROLE, account);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) public virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function transferOwnership(address newAdmin) public virtual onlyOwner {
        transferAdmin(newAdmin);
    }

    function renounceOwnership() public onlyOwner {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function renounceMinter() public {
        renounceRole(MINTER_ROLE, msg.sender);
    }

    function renounceOperator() public {
        renounceRole(OPERATOR_ROLE, msg.sender);
    }

    function revokeMinter(address account) public onlyOwner {
        revokeRole(MINTER_ROLE, account);
    }

    function revokeOperator(address account) public onlyOwner {
        revokeRole(OPERATOR_ROLE, account);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isOwner() public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function isMinter(address account) public view virtual returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function isOperator(address account) public view virtual returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Storage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}