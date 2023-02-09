pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Whitelist
 *
 * SPDX-License-Identifier: MIT
 * 
 * CRYPTOGATE
 * 
 * https://cryptogate.ch
 *
 **/
 
contract Roles is AccessControl {
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    bytes32 public constant BLOCKLISTED_ROLE = keccak256("BLOCKLISTED_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");


    constructor(address _owner, address _whitelister) {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MANAGER_ROLE, _owner);
        _grantRole(WHITELISTED_ROLE, _owner);
        _grantRole(WHITELISTER_ROLE, _whitelister);
    }

    function grantWhitelistedRole(address _investor)
        external
        onlyRole(WHITELISTER_ROLE)
    {
        require(
            !hasRole(WHITELISTED_ROLE, _investor),
            "Address is already whitelisted"
        );
        _grantRole(WHITELISTED_ROLE, _investor);
    }

    function revokeWhitelistedRole(address _investor)
        external
        onlyRole(WHITELISTER_ROLE)
    {
        require(
            hasRole(WHITELISTED_ROLE, _investor),
            "Address is not whitelisted"
        );
        _revokeRole(WHITELISTED_ROLE, _investor);
    }
}