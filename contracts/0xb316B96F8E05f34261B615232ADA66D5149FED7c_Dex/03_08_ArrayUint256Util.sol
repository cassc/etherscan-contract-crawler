// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ArrayUint256Util {
  function indexOf(uint256[] storage values, uint256 value) internal view returns(bool, uint) {
    for (uint i = 0; i < values.length; i += 1) {
      if (values[i] == value) {
        return (true, i);
      }
    }

    return (false, 0);
  }

  function removeByValue(uint256[] storage values, uint256 value) internal {
    (bool success, uint index) = indexOf(values, value);

    if (success) {
      removeByIndex(values, index);
    }
  }

  function removeByIndex(uint256[] storage values, uint index) internal {
    for (uint i = index; i < values.length - 1; i += 1) {
      values[i] = values[i+1];
    }

    delete values[values.length - 1];
  }
}