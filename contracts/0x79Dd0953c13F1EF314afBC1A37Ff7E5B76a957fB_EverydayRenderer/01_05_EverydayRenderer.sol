// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

interface IEverydayRenderer {
  function render(uint256 tokenId) external view returns (string memory);
}

contract EverydayRenderer is Ownable, IEverydayRenderer {
  using Strings for uint256;

  string private baseURI = 'https://everyday.photo/tokenURI/';

  function setBaseURI(string memory uri) external onlyOwner {
    baseURI = uri;
  }

  function render(uint256 tokenId) external view override returns (string memory) {
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
  }
}