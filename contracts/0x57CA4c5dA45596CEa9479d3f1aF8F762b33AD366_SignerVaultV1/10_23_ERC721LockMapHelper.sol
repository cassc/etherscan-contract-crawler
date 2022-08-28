// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "../interfaces/lightweight/IERC721.sol";
import "../structs/LockMap.sol";

library ERC721LockMapHelper {
  function addERC721(LockMap storage lockMap, uint tokenId, uint until) internal {
    lockMap.untils.push(until);
    lockMap.values.push(tokenId);
    lockMap.length++;
    validateERC721s(lockMap);
  }

  function removeERC721(LockMap storage lockMap, uint tokenId) internal {
    removeERC721(lockMap, tokenId, false);
  }

  function removeERC721(LockMap storage lockMap, uint tokenId, bool forced) internal returns (uint) {
    uint length = lockMap.length;
    uint indexToRemove = length;
    uint until;

    for (uint index = 0; index < length; index++) {
      if (lockMap.values[index] == tokenId && (forced || lockMap.untils[index] <= block.timestamp)) {
        until = lockMap.untils[index];
        indexToRemove = index;
        break;
      }
    }

    require(indexToRemove != length, "ERC721LockMapHelper: INSUFFICIENT_UNLOCKABLE_BALANCE");

    uint lastIndex = lockMap.length - 1;
    if (indexToRemove != lastIndex) {
      lockMap.untils[indexToRemove] = lockMap.untils[lastIndex];
      lockMap.values[indexToRemove] = lockMap.values[lastIndex];
    }

    lockMap.untils.pop();
    lockMap.values.pop();
    lockMap.length--;
    validateERC721s(lockMap);
    return until;
  }

  function validateERC721s(LockMap storage lockMap) internal view {
    uint length = lockMap.length;

    uint expectedBalance = length;
    uint balance = IERC721(lockMap.id).balanceOf(address(this));
    require(expectedBalance <= balance, "ERC721LockMapHelper: BALANCE_MISMATCH");

    for (uint index = 0; index < length; index++)
      require(address(this) == IERC721(lockMap.id).ownerOf(lockMap.values[index]), "ERC721LockMapHelper: OWNER_MISMATCH");
  }

  function canUnlockERC721(LockMap storage lockMap, uint tokenId) internal view returns (bool) {
    uint length = lockMap.length;

    for (uint index = 0; index < length; index++)
      if (lockMap.values[index] == tokenId && lockMap.untils[index] <= block.timestamp)
        return true;

    return false;
  }

  function balanceERC721s(LockMap storage lockMap) internal view returns (uint) {
    return lockMap.length;
  }
}