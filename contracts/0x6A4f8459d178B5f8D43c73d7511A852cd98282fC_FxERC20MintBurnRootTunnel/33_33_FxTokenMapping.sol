// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

abstract contract FxTokenMapping {
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");

    mapping(address => address) public rootToChildToken;
}