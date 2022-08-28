// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "../interfaces/lightweight/IERC20.sol";
import "../structs/LockMap.sol";

library TokenLockMapHelper {
  function addTokens(LockMap storage lockMap, uint amount, uint until) internal {
    uint length = lockMap.length;

    for (uint index = 0; index < length; index++) {
      if (lockMap.untils[index] == until) {
        lockMap.values[index] += amount;
        validateTokens(lockMap);
        return;
      }
    }

    lockMap.untils.push(until);
    lockMap.values.push(amount);
    lockMap.length++;
    validateTokens(lockMap);
  }

  function removeTokens(LockMap storage lockMap, uint amount) internal {
    removeTokens(lockMap, amount, false);
  }

  function removeTokens(LockMap storage lockMap, uint amount, bool forced) internal returns (uint) {
    uint length = lockMap.length;
    bool[] memory indicesToRemove = new bool[](length);
    uint until;

    uint amountToRemove;
    for (uint index = 0; index < length; index++) {
      if (forced || lockMap.untils[index] <= block.timestamp) {
        amountToRemove = amount > lockMap.values[index] ? lockMap.values[index] : amount;
        amount -= amountToRemove;
        lockMap.values[index] -= amountToRemove;
        if (lockMap.untils[index] > until)
          until = lockMap.untils[index];
        if (lockMap.values[index] == 0)
          indicesToRemove[index] = true;
        if (amount == 0)
          break;
      }
    }

    require(amount == 0, "TokenLockMapHelper: INSUFFICIENT_UNLOCKABLE_BALANCE");

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
    validateTokens(lockMap);
    return until;
  }

  function validateTokens(LockMap storage lockMap) internal view {
    uint length = lockMap.length;

    uint expectedBalance = 0;
    for (uint index = 0; index < length; index++)
      expectedBalance += lockMap.values[index];

    uint balance = lockMap.id == address(0) ? address(this).balance : IERC20(lockMap.id).balanceOf(address(this));
    require(expectedBalance <= balance, "TokenLockMapHelper: BALANCE_MISMATCH");
  }

  function canUnlockTokens(LockMap storage lockMap, uint amount) internal view returns (bool) {
    uint length = lockMap.length;

    uint balance = 0;
    for (uint index = 0; index < length; index++)
      if (lockMap.untils[index] <= block.timestamp)
        balance += lockMap.values[index];

    return balance >= amount;
  }

  function balanceTokens(LockMap storage lockMap) internal view returns (uint) {
    uint length = lockMap.length;
    uint balance;

    for (uint index = 0; index < length; index++)
      balance += lockMap.values[index];

    return balance;
  }
}