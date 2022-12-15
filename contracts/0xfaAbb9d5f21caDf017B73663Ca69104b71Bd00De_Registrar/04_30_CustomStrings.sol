// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library CustomStrings {
  function toString(
    uint256 value
  ) internal pure returns (string memory _uintAsString) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      uint8 tempo = (48 + uint8(value - (value / 10) * 10));
      bytes1 b1 = bytes1(tempo);
      buffer[digits] = b1;
      value /= 10;
    }
    return string(buffer);
  }
}