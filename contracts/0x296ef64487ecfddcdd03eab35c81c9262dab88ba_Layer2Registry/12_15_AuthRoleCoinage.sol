//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AuthRoleCoinage {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
}