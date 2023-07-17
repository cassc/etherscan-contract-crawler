//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IItemType.sol";
import "./IEquipment.sol";

interface ISlothEquipment {
  function validateSetItems(uint256[] calldata equipmentItemIds, IEquipment.EquipmentTargetItem[] calldata equipmentTargetItems, address sender) external view returns (bool);
  function getTargetItemContractAddress(IItemType.ItemMintType _itemMintType) external view returns (address);
}