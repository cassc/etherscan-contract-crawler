// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { AccessControlUpgradeable } from "./AccessControlUpgradeable.sol";

library AccessControlStorage {

  struct Layout {

    mapping(bytes32 => AccessControlUpgradeable.RoleData) _roles;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.AccessControl');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}