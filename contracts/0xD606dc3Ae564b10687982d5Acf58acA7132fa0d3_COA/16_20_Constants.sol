// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
bytes32 constant CREATE_ROLE = keccak256("CREATE_ROLE"); // role to create new identities
bytes32 constant UPDATE_DELETE_ROLE = keccak256("UPDATE_DELETE_ROLE"); // role to update or delete identities and certificates