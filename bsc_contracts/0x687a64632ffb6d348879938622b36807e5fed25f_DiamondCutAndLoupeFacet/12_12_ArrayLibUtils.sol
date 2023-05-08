// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Bytes4ArrayLibUtils {
  function indexOf(bytes4[] memory array, bytes4 value) internal pure returns (uint256) {
    uint256 length = array.length;
    for (uint256 i = 0; i < length; ) {
      if (array[i] == value) return i;
      unchecked {
        ++i;
      }
    }
    return type(uint256).max;
  }

  function filterOut(bytes4[] memory array, bytes4 value) internal pure returns (bytes4[] memory) {
    uint256 index = indexOf(array, value);
    if (index == type(uint256).max) return array;

    bytes4[] memory newArray = new bytes4[](array.length - 1);
    for (uint256 i = 0; i < index; ) {
      newArray[i] = array[i];
      unchecked {
        ++i;
      }
    }
    uint256 length = newArray.length;
    for (uint256 i = index; i < length; ) {
      newArray[i] = array[i + 1];
      unchecked {
        ++i;
      }
    }
    return newArray;
  }
}

library AddressArrayLibUtils {
  function indexOf(address[] memory array, address value) internal pure returns (uint256) {
    for (uint256 i = 0; i < array.length; ) {
      if (array[i] == value) return i;
      unchecked {
        ++i;
      }
    }
    return type(uint256).max;
  }

  function filterOut(
    address[] memory array,
    address value
  ) internal pure returns (address[] memory) {
    uint256 index = indexOf(array, value);
    if (index == type(uint256).max) return array;

    address[] memory newArray = new address[](array.length - 1);
    for (uint256 i = 0; i < index; ) {
      newArray[i] = array[i];
      unchecked {
        ++i;
      }
    }
    uint256 length = newArray.length;
    for (uint256 i = index; i < length; ) {
      newArray[i] = array[i + 1];
      unchecked {
        ++i;
      }
    }
    return newArray;
  }

  function swapOut(address[] storage array, address value) internal {
    uint256 index = indexOf(array, value);
    address last = array[array.length - 1];
    array[index] = last;
    array.pop();
  }
}