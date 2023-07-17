//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ISlothItemV3.sol";
import "./interfaces/ISpecialSlothItem.sol";
import "./interfaces/IItemType.sol";
import "./interfaces/IEquipment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SlothEquipment is Ownable {
  address private _slothAddr;
  address private _slothItemAddr;
  address private _specialSlothItemAddr;
  address private _userGeneratedSlothItemAddr;
  uint8 private constant _ITEM_NUM = 5;

  function _getSpecialType(uint256 _itemTokenId) internal view returns (uint256) {
    ISpecialSlothItem specialSlothItem = ISpecialSlothItem(_specialSlothItemAddr);
    return specialSlothItem.getSpecialType(_itemTokenId);
  }

  function _checkIsCombinationalCollabo(uint256 _specialType) internal view returns (bool) {
    ISpecialSlothItem specialSlothItem = ISpecialSlothItem(_specialSlothItemAddr);
    return specialSlothItem.isCombinational(_specialType);
  }

  function _checkOwner(uint256 _itemTokenId, IItemType.ItemMintType _itemMintType, address sender) internal view {
    if (_itemMintType == IItemType.ItemMintType.SLOTH_ITEM) {
      ISlothItemV3 slothItem = ISlothItemV3(_slothItemAddr);
      require(slothItem.exists(_itemTokenId), "token not exists");
      require(slothItem.ownerOf(_itemTokenId) == sender, "not owner");
      return;
    }
    
    if (uint(_itemMintType) == uint(IItemType.ItemMintType.SPECIAL_SLOTH_ITEM)) {
      ISpecialSlothItem specialSlothItem = ISpecialSlothItem(_specialSlothItemAddr);
      require(specialSlothItem.exists(_itemTokenId), "token not exists");
      require(specialSlothItem.ownerOf(_itemTokenId) == sender, "not owner");  
      return;
    }

    revert("wrorng itemMintType");
  }

  function _checkItemType(uint256 _itemTokenId, IItemType.ItemMintType _itemMintType, IItemType.ItemType _itemType) internal view {
    if (_itemMintType == IItemType.ItemMintType.SLOTH_ITEM) {
      ISlothItemV3 slothItem = ISlothItemV3(_slothItemAddr);
      require(slothItem.getItemType(_itemTokenId) == _itemType, "wrong item type");
      return;
    }

    if (_itemMintType == IItemType.ItemMintType.SPECIAL_SLOTH_ITEM) {
      ISpecialSlothItem specialSlothItem = ISpecialSlothItem(_specialSlothItemAddr);
      require(specialSlothItem.getItemType(_itemTokenId) == _itemType, "wrong item type");
      return;
    }

    revert("wrorng itemMintType");
  }

  function validateSetItems(uint256[] calldata equipmentItemIds, IEquipment.EquipmentTargetItem[] calldata equipmentTargetItems, address sender) external view returns (bool) {
    uint8 equipmentTargetSlothItemNum = 0;
    uint8 specialItemCount = 0;
    uint256 latestSpecialType = 99;
    bool latestSpecialTypeCombinationable = true;
  
    for (uint8 i = 0; i < _ITEM_NUM; i++) {
      uint256 _itemTokenId = equipmentTargetItems[i].itemTokenId;
      IItemType.ItemMintType _itemMintType = equipmentTargetItems[i].itemMintType;
      // token存在チェック、オーナーチェック
      if (_itemTokenId != 0) {
        if (equipmentItemIds[i] != _itemTokenId) {
          _checkOwner(_itemTokenId, _itemMintType, sender);
        }

        if (_itemMintType == IItemType.ItemMintType.SPECIAL_SLOTH_ITEM) {
          _checkItemType(_itemTokenId, _itemMintType, IItemType.ItemType(i));
          // コラボアイテムだった場合に、併用可不可のチェックを行う
          uint256 _specialType = _getSpecialType(_itemTokenId);
          if (latestSpecialType != _specialType) {
            bool combinationable = _checkIsCombinationalCollabo(_specialType);
            latestSpecialTypeCombinationable = combinationable;
            specialItemCount++;
            if (specialItemCount >= 2) {
              // 2個目以降のコラボが出てきたときにconbinationのチェックを行う
              if (combinationable && latestSpecialTypeCombinationable) {
                // 併用可の場合は何もしない
              } else {
                // 併用不可の場合はエラーを返す
                revert("not combinationable");
              }
            }
            latestSpecialType = _specialType;
          }
        } else {
          _checkItemType(_itemTokenId, _itemMintType, IItemType.ItemType(i));

          equipmentTargetSlothItemNum++;
        }
      }
    }
    if (latestSpecialTypeCombinationable == false && equipmentTargetSlothItemNum > 0) {
      revert("not combinationable");
    }
    return true;
  }

  function getTargetItemContractAddress(IItemType.ItemMintType _itemMintType) external view returns (address) {
    if (_itemMintType == IItemType.ItemMintType.SLOTH_ITEM) {
      return _slothItemAddr;
    } else if (_itemMintType == IItemType.ItemMintType.SPECIAL_SLOTH_ITEM) {
      return _specialSlothItemAddr;
    } else if (_itemMintType == IItemType.ItemMintType.USER_GENERATED_SLOTH_ITEM) {
      return _userGeneratedSlothItemAddr;
    } else {
      revert("invalid itemMintType");
    }
  }

  function setSlothAddr(address newSlothAddr) external onlyOwner {
    _slothAddr = newSlothAddr;
  }
  function setSlothItemAddr(address newSlothItemAddr) external onlyOwner {
    _slothItemAddr = newSlothItemAddr;
  }
  function setSpecialSlothItemAddr(address newSpecialSlothItemAddr) external onlyOwner {
    _specialSlothItemAddr = newSpecialSlothItemAddr;
  }
}