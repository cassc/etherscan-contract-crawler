// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library ERC1155BaseStorage {
  struct Layout {
    mapping(uint256 => mapping(address => uint256)) balances;
    mapping(address => mapping(address => bool)) operatorApprovals;
    mapping(uint256 => TokenData) tokenInfo;
    mapping(address => uint256[]) creatorTokens;
  }

  struct TokenData {
    uint256 tokenPrice;
    uint256 maxSupply;
    uint8 percentage;
    address creatorAccount;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("komon.contracts.storage.ERC1155Base");

  function layout() internal pure returns (Layout storage lay) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      lay.slot := slot
    }
  }
}
