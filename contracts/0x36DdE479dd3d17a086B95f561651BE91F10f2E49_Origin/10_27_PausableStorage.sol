// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { PausableUpgradeable } from "./PausableUpgradeable.sol";

library PausableStorage {

  struct Layout {

    bool _paused;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.Pausable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}