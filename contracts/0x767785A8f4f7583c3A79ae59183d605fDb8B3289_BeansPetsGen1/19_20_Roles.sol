// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Openzeppelin Contracts
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Roles is AccessControl {
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                                ROLES
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    bytes32 internal constant ROLE_SERVER = keccak256("ROLE_SERVER");

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    constructor() {
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *                    SET ROLES
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Give every role to the owner of the contract
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ROLE_SERVER, DEFAULT_ADMIN_ROLE);
        _grantRole(Roles.ROLE_SERVER, msg.sender);

        // !! Aditional Roles also set in Settings.sol constructor !!
    }
}