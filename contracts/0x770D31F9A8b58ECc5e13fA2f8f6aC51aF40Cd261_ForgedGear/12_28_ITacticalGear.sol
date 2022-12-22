// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'erc721a/contracts/extensions/IERC721AQueryable.sol';

interface ITacticalGear is IERC721AQueryable {
  struct Item {
    string category;
    string name;
  }

  struct TacticalGear {
    string fullName;
    string name;
    string category;
    string suffix;
  }

  function getItem(uint256 tokenId) external view returns (Item memory);

  function getPrefix(uint256 tokenId) external view returns (string memory);

  function getSuffix(uint256 tokenId) external view returns (string memory);

  function hasR0N1(uint256 tokenId) external view returns (bool);

  function getGear(uint256 tokenId) external view returns (TacticalGear memory);

  function getImage(uint256 tokenId) external view returns (string memory);

  function getCardImage(uint256 tokenId) external view returns (string memory);
}