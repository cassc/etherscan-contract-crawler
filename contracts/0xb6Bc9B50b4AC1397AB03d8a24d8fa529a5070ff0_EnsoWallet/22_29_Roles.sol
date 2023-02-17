// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

abstract contract Roles {
    // Using same slot generation technique as eip-1967 -- https://eips.ethereum.org/EIPS/eip-1967
    bytes32 public constant OWNER_ROLE = bytes32(uint256(keccak256("enso.access.roles.owner")) - 1);
    bytes32 public constant EXECUTOR_ROLE = bytes32(uint256(keccak256("enso.access.roles.executor")) - 1);
    bytes32 public constant MODULE_ROLE = bytes32(uint256(keccak256("enso.access.roles.module")) - 1);
}