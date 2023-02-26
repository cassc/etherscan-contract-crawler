// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ArrayAddressUtil {
  function indexOf(address[] storage values, address value) internal view returns(bool, uint) {
    for (uint i = 0; i < values.length; i += 1) {
      if (values[i] == value) {
        return (true, i);
      }
    }

    return (false, 0);
  }

  function removeByValue(address[] storage values, address value) internal {
    (bool success, uint index) = indexOf(values, value);

    if (success) {
      removeByIndex(values, index);
    }
  }

  function removeByIndex(address[] storage values, uint index) internal {
    for (uint i = index; i < values.length - 1; i += 1) {
      values[i] = values[i+1];
    }

    delete values[values.length - 1];
  }
}