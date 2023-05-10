// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

/// @custom:salt MockWithConstructor
contract MockWithConstructor {
    uint256 public immutable constructorValue;

    constructor(uint256 _constructorValue) {
        constructorValue = _constructorValue;
    }
}