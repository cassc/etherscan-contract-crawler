//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC721AQueryableUpgradeable } from "erc721a-upgradeable/contracts/interfaces/IERC721AQueryableUpgradeable.sol";

interface ISlothItemV2 is IERC721AQueryableUpgradeable {
  enum ItemType { CLOTHES, HEAD, HAND, FOOT, STAMP }

  function getItemType(uint256 tokenId) external view returns (ItemType);
  function getItemMintCount(address sender) external view returns (uint256);
  function exists(uint256 tokenId) external view returns (bool);
  function clothesMint(address sender, uint256 quantity) external;
  function itemMint(address sender, uint256 quantity) external;
}