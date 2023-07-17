//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IItemType {
  enum ItemType { CLOTHES, HEAD, HAND, FOOT, STAMP }
  enum ItemMintType { SLOTH_ITEM, SPECIAL_SLOTH_ITEM, USER_GENERATED_SLOTH_ITEM }
}