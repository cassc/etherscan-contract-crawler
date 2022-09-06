// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

library AddressArrayHelper {
  function remove(address[] storage array, address item) internal returns (bool) {
    for (uint index = 0; index < array.length; index++) {
      if (array[index] == item) {
        uint lastIndex = array.length - 1;
        if (index != lastIndex)
          array[index] = array[lastIndex];
        array.pop();
        return true;
      }
    }

    return false;
  }
}