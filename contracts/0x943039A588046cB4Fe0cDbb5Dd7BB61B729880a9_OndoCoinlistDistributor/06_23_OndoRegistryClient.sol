// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "contracts/OndoRegistryClientInitializable.sol";

abstract contract OndoRegistryClient is OndoRegistryClientInitializable {
  constructor(address _registry) {
    __OndoRegistryClient__initialize(_registry);
  }
}