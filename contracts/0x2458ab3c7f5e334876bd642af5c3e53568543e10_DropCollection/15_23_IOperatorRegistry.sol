// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOperatorRegistry {
    event OperatorIdentified(
        bytes32 indexed identifer,
        address indexed operator
    );

    function getIdentifier(address operator) external view returns (bytes32);
}