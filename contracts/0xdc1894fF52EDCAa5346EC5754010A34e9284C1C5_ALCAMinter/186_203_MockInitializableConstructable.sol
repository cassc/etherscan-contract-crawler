// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "test/contract-mocks/factory/MockInitializable.sol";

/// @custom:salt MockInitializableConstructable
contract MockInitializableConstructable is MockInitializable {
    uint256 public immutable constructorValue;

    constructor(uint256 _constructorValue) {
        constructorValue = _constructorValue;
    }
}