//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AuthRoleSeigManager {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
    bytes32 public constant CHALLENGER_ROLE = keccak256("CHALLENGER");
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE");
}