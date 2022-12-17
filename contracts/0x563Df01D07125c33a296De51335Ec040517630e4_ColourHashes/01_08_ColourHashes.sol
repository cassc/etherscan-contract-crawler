// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";

error TokenIdAlreadySet();

contract ColourHashes is AccessControl {
  mapping(uint256 => bytes32) public tokenIdToColourHash;
  mapping(uint256 => bool) public idsSet;

  event ColourHashSet(uint256 indexed tokenId, bytes32 colourHash);

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function storeColourHash(uint256 tokenId, bytes32 colourHash)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (idsSet[tokenId]) revert TokenIdAlreadySet();
    idsSet[tokenId] = true;
    tokenIdToColourHash[tokenId] = colourHash;
    emit ColourHashSet(tokenId, colourHash);
  }
}