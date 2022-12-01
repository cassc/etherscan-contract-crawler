//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

abstract contract Roles {
    bytes32 public constant OWNER_ROLE = keccak256("enso.access.roles.owner");
    bytes32 public constant EXECUTOR_ROLE = keccak256("enso.access.roles.executor");
}