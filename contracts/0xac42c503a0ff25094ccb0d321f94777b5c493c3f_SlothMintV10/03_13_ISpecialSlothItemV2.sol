//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IItemType.sol";
import { IERC721AQueryableUpgradeable } from "erc721a-upgradeable/contracts/interfaces/IERC721AQueryableUpgradeable.sol";

interface ISpecialSlothItemV2 is IERC721AQueryableUpgradeable, IItemType {
  function getItemType(uint256 tokenId) external view returns (ItemType);
  function getSpecialType(uint256 tokenId) external view returns (uint256);
  function getClothType(uint256 tokenId) external view returns (uint256);
  function exists(uint256 tokenId) external view returns (bool);
  function isCombinational(uint256 _specialType) external view returns (bool);
  function mintPoupelle(address sender, uint256 quantity) external;
  function mintCollaboCloth(address sender, uint256 quantity, uint256 _specialType) external;
  function mintHalloweenJiangshiSet(address sender, uint256 quantity) external;
  function mintHalloweenJacKOLanternSet(address sender, uint256 quantity) external;
  function mintHalloweenGhostSet(address sender, uint256 quantity) external;
}