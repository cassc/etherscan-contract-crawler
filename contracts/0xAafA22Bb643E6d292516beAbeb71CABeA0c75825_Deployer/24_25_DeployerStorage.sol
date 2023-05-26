// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

library DeployerStorage {
  struct Layout {
    mapping(uint256 => bool) noncesUsed; // TODO: voucher to deploy
    // TODO: supported target addresses?
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("originsecured.contracts.storage.deployer.v1");

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}