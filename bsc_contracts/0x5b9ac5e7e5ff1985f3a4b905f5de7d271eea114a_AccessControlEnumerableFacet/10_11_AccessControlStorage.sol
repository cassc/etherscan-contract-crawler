// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct RoleData {
  mapping(address => bool) members;
  bytes32 adminRole;
}

struct AccessControlStorage {
  mapping(bytes32 => RoleData) roles;
}