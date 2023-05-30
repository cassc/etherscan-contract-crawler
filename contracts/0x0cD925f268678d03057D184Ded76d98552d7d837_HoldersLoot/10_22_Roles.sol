// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Openzeppelin Contracts
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Roles is AccessControl {
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                                ROLES
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// Description: This role is for the Gnosis safe to ensure actions taken are approved by more than 1 person
    /// Permissions:
    /// - setURI
    /// - setPause
    /// - unpause
    /// - addLootItem
    /// - updateLootItem
    /// - removeLootItem
    /// - setSignerAddress
    /// - setDailyStoreActive
    bytes32 internal constant ROLE_SAFE = keccak256("ROLE_SAFE");

    /// Description: The role of the server to update daily store and setting the daily store active or not
    /// Permissions:
    /// - setDailyStore
    /// - setDailyStoreActive
    bytes32 internal constant ROLE_SERVER = keccak256("ROLE_SERVER");
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    constructor() {
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *                    SET ROLES
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Give every role to the owner of the contract
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setRoleAdmin(ROLE_SAFE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ROLE_SERVER, DEFAULT_ADMIN_ROLE);

        _grantRole(Roles.ROLE_SAFE, msg.sender);
        _grantRole(Roles.ROLE_SERVER, msg.sender);

        // Aditional Roles also set in Settings.sol constructor
    }
}