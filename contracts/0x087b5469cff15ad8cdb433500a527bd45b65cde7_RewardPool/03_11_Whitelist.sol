// Whitelist.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

/*
 * Implements Whitelisting pattern using OpenZeppelin AccessRole
 */
contract Whitelist is AccessControl {
    bytes32 public constant WHITELIST_ADMIN = keccak256("WHITELIST_ADMIN");
    bytes32 public constant WHITELISTED = keccak256("WHITELISTED");

    constructor() {
        _setRoleAdmin(WHITELIST_ADMIN, WHITELIST_ADMIN);
        _setRoleAdmin(WHITELISTED, WHITELIST_ADMIN);
        _setupRole(WHITELIST_ADMIN, msg.sender);
    }

    modifier onlyWhitelistAdmin {
        require(hasRole(WHITELIST_ADMIN, msg.sender), "Caller is not a whitelist admin");
        _;
    }

    modifier onlyWhitelisted {
        require(hasRole(WHITELISTED, msg.sender), "Caller is not a whitelisted");
        _;
    }

    function addWhitelistAdmin(address account)
        onlyWhitelistAdmin
        external
    {
        grantRole(WHITELIST_ADMIN, account);
    }

    function removeWhitelistAdmin(address account) 
        onlyWhitelistAdmin
        external 
    {
        revokeRole(WHITELIST_ADMIN, account);
    }

    function addWhitelisted(address account) 
        onlyWhitelistAdmin 
        external 
    {
        grantRole(WHITELISTED, account);
    }

    function removeWhitelisted(address account) 
        onlyWhitelistAdmin
        external 
    {
        revokeRole(WHITELISTED, account);
    }

    function isWhitelisted(address account)
        external
        view
        returns (bool)
    {
        return hasRole(WHITELISTED, account);
    }

    function isWhitelistAdmin(address account)
        external
        view
        returns (bool)
    {
        return hasRole(WHITELIST_ADMIN, account);
    }
}