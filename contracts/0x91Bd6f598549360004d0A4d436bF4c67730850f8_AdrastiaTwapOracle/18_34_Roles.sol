// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

library Roles {
    bytes32 public constant ADMIN = keccak256("ADMIN_ROLE");

    bytes32 public constant ORACLE_UPDATER = keccak256("ORACLE_UPDATER_ROLE");
}