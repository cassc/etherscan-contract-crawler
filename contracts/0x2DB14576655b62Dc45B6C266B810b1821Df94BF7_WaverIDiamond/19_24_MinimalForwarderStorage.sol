// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { MinimalForwarderUpgradeable } from "./MinimalForwarderUpgradeable.sol";

library MinimalForwarderStorage {

  struct Layout {

    mapping(address => uint256) _nonces;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.MinimalForwarder');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}