// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { Initializable } from "./Initializable.sol";

library InitializableStorage {

  struct Layout {
    /*
     * @dev Indicates that the contract has been initialized.
     */
    bool _initialized;

    /*
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool _initializing;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.Initializable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}