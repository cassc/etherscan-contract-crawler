// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";

abstract contract ERC721Mintable is ERC721Burnable, Ownable {
  constructor(string memory _name, string memory _symbol)
    ERC721(_name, _symbol) {
  }

  function mint(address to, uint256 tokenId) onlyOwner external {
    _mint(to, tokenId);
  }

  function transfer(address to, uint256 tokenId) external {
    _transfer(msg.sender, to, tokenId);
  }
}