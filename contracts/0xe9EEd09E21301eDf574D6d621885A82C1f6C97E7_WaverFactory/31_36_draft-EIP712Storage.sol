// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { EIP712Upgradeable } from "./draft-EIP712Upgradeable.sol";

library EIP712Storage {

  struct Layout {
    /* solhint-disable var-name-mixedcase */
    bytes32 _HASHED_NAME;
    bytes32 _HASHED_VERSION;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.EIP712');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}