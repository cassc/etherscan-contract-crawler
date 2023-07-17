//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC721AQueryableUpgradeable } from "erc721a-upgradeable/contracts/interfaces/IERC721AQueryableUpgradeable.sol";
import "./IItemType.sol";

interface ISlothItemV3 is IERC721AQueryableUpgradeable {
  function getItemType(uint256 tokenId) external view returns (IItemType.ItemType);
  function getItemMintCount(address sender) external view returns (uint256);
  function exists(uint256 tokenId) external view returns (bool);
  function clothesMint(address sender, uint256 quantity) external;
  function itemMint(address sender, uint256 quantity) external;
}