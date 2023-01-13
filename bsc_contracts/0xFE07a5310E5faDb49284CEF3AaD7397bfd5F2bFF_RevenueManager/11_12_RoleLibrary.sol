// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

library Roles {
    bytes32 internal constant ADMIN = "admin";
    bytes32 internal constant REVENUE_MANAGER = "revenue_manager";
    bytes32 internal constant MISSION_TERMINATOR = "mission_terminator";
    bytes32 internal constant DAPP_GUARD = "dapp_guard";
    bytes32 internal constant DAPP_GUARD_KILLER = "dapp_guard_killer";
    bytes32 internal constant MISSION_CONFIGURATOR = "mission_configurator";
    bytes32 internal constant VAULT_WITHDRAWER = "vault_withdrawer";
}