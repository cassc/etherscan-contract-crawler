// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./TransferHelperV2.sol";
import "../structs/LockMap.sol";

library CurrencyLockMapHelper {
  function add(LockMap storage lockMap, CurrencyType currencyType, uint value, uint until) internal {
    if (currencyType != CurrencyType.ERC721) {
      uint length = lockMap.length;

      for (uint index = 0; index < length; index++) {
        if (lockMap.untils[index] == until) {
          lockMap.values[index] += value;
          validate(lockMap, currencyType);
          return;
        }
      }
    }

    lockMap.untils.push(until);
    lockMap.values.push(value);
    lockMap.length++;
    validate(lockMap, currencyType);
  }

  function remove(LockMap storage lockMap, CurrencyType currencyType, uint value) internal {
    remove(lockMap, currencyType, value, false);
  }

  function remove(LockMap storage lockMap, CurrencyType currencyType, uint value, bool forced) internal returns (uint) {
    uint length = lockMap.length;
    bool[] memory indicesToRemove = new bool[](length);
    uint until;

    if (currencyType == CurrencyType.ERC721) {
      for (uint index = 0; index < length; index++) {
        if (lockMap.values[index] == value && (forced || lockMap.untils[index] <= block.timestamp)) {
          value = 0;
          until = lockMap.untils[index];
          indicesToRemove[index] = true;
          break;
        }
      }
    } else {
      uint amountToRemove;
      for (uint index = 0; index < length; index++) {
        if (forced || lockMap.untils[index] <= block.timestamp) {
          amountToRemove = value > lockMap.values[index] ? lockMap.values[index] : value;
          value -= amountToRemove;
          lockMap.values[index] -= amountToRemove;
          if (lockMap.untils[index] > until)
            until = lockMap.untils[index];
          if (lockMap.values[index] == 0)
            indicesToRemove[index] = true;
          if (value == 0)
            break;
        }
      }
    }

    require(value == 0, "CurrencyLockMap: INSUFFICIENT_UNLOCKABLE_BALANCE");

    uint lastIndex; 
    uint indexToRemove;
    for (uint index = length; index > 0; index--) {
      indexToRemove = index - 1;
      if (indicesToRemove[indexToRemove]) {
        lastIndex = lockMap.length - 1;
        if (indexToRemove != lastIndex) {
          lockMap.untils[indexToRemove] = lockMap.untils[lastIndex];
          lockMap.values[indexToRemove] = lockMap.values[lastIndex];
        }

        lockMap.untils.pop();
        lockMap.values.pop();
        lockMap.length--;
      }
    }
    validate(lockMap, currencyType);
    return until;
  }

  function validate(LockMap storage lockMap, CurrencyType currencyType) internal view {
    uint length = lockMap.length;
    uint balance_ = TransferHelperV2.safeBalanceOf(lockMap.id, address(this));

    if (currencyType == CurrencyType.ERC721) {
      uint expectedBalance = length;
      require(expectedBalance <= balance_, "CurrencyLockMap: BALANCE_MISMATCH");

      for (uint index = 0; index < length; index++)
        require(address(this) == TransferHelperV2.safeOwnerOf(lockMap.id, lockMap.values[index]), "CurrencyLockMap: OWNER_MISMATCH");
    } else {
      uint expectedBalance = 0;
      for (uint index = 0; index < length; index++)
        expectedBalance += lockMap.values[index];

      require(expectedBalance <= balance_, "CurrencyLockMap: BALANCE_MISMATCH");
    }
  }

  function canUnlock(LockMap storage lockMap, CurrencyType currencyType, uint value) internal view returns (bool) {
    uint length = lockMap.length;

    if (currencyType == CurrencyType.ERC721) {
      for (uint index = 0; index < length; index++)
      if (lockMap.values[index] == value && lockMap.untils[index] <= block.timestamp)
        return true;

      return false;
    }

    uint balance_ = 0;
    for (uint index = 0; index < length; index++)
      if (lockMap.untils[index] <= block.timestamp)
        balance_ += lockMap.values[index];

    return balance_ >= value;
  }

  function balance(LockMap storage lockMap, CurrencyType currencyType) internal view returns (uint) {
    if (currencyType == CurrencyType.ERC721)
      return lockMap.length;

    uint length = lockMap.length;
    uint balance_;

    for (uint index = 0; index < length; index++)
      balance_ += lockMap.values[index];

    return balance_;
  }
}