//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UnemployablesPlus is ERC1155, Ownable {
  string public constant name = "Unemployables+";
  string public constant symbol = "UNE+";

  string[] private tokenMetadata;

  constructor() ERC1155(""){}

  function uri(uint256 tokenId) public view override returns (string memory) {
      return tokenMetadata[tokenId - 1];
  }

  function create(string calldata metadata, uint256 editions) external onlyOwner {
      tokenMetadata.push(metadata);
      _mint(msg.sender, tokenMetadata.length, editions, "");
  }

  // Emergency
  function update(uint256 tokenId, string calldata metadata) external onlyOwner {
      tokenMetadata[tokenId - 1] = metadata;
  }
}