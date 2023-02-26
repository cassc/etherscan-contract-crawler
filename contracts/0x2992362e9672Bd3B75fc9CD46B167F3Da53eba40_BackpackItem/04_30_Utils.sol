// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library Utils {
  function uintToString(uint v) internal pure returns (string memory) {
    uint maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint i = 0;

    while (v != 0) {
      uint remainder = v % 10;
      v = v / 10;
      reversed[i++] = bytes1(uint8(48 + remainder));
    }
    bytes memory s = new bytes(i);

    for (uint j = 0; j < i; ) {
      s[j] = reversed[i - j - 1];
      unchecked {
        ++j;
      }
    }

    string memory str = string(s);
    return str;
  }

  function sumArray(uint256[] memory amounts) internal pure returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < amounts.length; ) {
      sum += amounts[i];
      unchecked {
        ++i;
      }
    }
    return sum;
  }

  function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b > a) return 0;
    return a - b;
  }

  function shuffle(uint[] memory uints) internal view returns (uint[] memory) {
    // Making a copy of the uints array, since modifying it from storage is really expensive
    // and we could get a out of gas exception
    uint[] memory uintsCopy = uints;

    uint counter = 0;
    uint j = 0;
    bytes32 b32 = keccak256(abi.encodePacked(block.timestamp + counter));
    uint length = uintsCopy.length;

    for (uint256 i = 0; i < uintsCopy.length; i++) {
      if (j > 31) {
        b32 = keccak256(abi.encodePacked(block.timestamp + ++counter));
        j = 0;
      }

      uint8 value = uint8(b32[j++]);

      uint256 n = value % length;

      uint temp = uintsCopy[n];
      uintsCopy[n] = uintsCopy[i];
      uintsCopy[i] = temp;
    }

    // Now, modifying the state uints array, once as a whole.
    uints = uintsCopy;

    return uintsCopy;
  }

  function uintToBytes(uint v) internal returns (bytes32 ret) {
    if (v == 0) {
      ret = "0";
    } else {
      while (v > 0) {
        ret = bytes32(uint(ret) / (2 ** 8));
        ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
        v /= 10;
      }
    }
    return ret;
  }
}