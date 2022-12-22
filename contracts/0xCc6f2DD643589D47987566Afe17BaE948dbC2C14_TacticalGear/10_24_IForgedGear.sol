// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IForgedGear is IERC721 {
  struct ForgedGear {
    string fullName;
    string name;
    string category;
    string prefix;
    string suffix;
    bool isForged;
    string extra;
  }

  function forge(address to, uint256 tokenId) external;

  function getForgedAt(uint256 tokenId) external view returns (uint256);

  function getForgedGear(uint256 tokenId) external view returns (ForgedGear memory);

  function getImage(uint256 tokenId) external view returns (string memory);

  function getCardImage(uint256 tokenId) external view returns (string memory);
}