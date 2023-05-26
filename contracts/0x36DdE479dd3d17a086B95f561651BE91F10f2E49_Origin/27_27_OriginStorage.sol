// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

library OriginStorage {
  struct Layout {
    string baseURI;
    mapping(uint256 => address) tokenIds;
    mapping(uint256 => bool) usedNonces;
    // Optional mapping for token URIs
    mapping(uint256 => string) _tokenURIs;
    address root; /// @dev TODO: allow more than 1 signer?
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("originsecured.origin.storage.v1");

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}