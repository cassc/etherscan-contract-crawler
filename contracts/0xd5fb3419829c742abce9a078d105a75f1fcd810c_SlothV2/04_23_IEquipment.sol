//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IItemType.sol";

interface IEquipment {
  struct EquipmentTargetItem {
    uint256 itemTokenId;
    IItemType.ItemMintType itemMintType; 
  }
  struct Equipment {
    uint256 itemId;
    address itemAddr;
  }
  struct EquipmentTargetSpecial {
    uint256 specialType;
    bool combinationable;
  }
}