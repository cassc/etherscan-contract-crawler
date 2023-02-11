// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721HexURI is ERC721 {
  using Strings for uint256;

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    string memory base = _baseURI();
    return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toHexString(32))) : "";
  }
}