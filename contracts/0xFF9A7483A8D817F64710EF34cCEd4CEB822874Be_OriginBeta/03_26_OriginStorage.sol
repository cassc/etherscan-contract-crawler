// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library OriginStorage {
  struct Layout {
    // Root
    address root;
    string baseURI;
    // Keys
    mapping(uint256 => address) keys;
    // Message nonces
    mapping(uint256 => bool) usedNonces;
    // Optional mapping for token URIs
    mapping(uint256 => string) _tokenURIs;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("roar.origin.storage.v1");

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}