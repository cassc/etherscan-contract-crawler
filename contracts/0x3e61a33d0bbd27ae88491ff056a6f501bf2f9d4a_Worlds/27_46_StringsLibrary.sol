// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

library StringsLibrary {
  using Strings for uint256;

  /**
   * @notice Converts a number into a string and adds leading "0"s so the total string length matches `digitCount`.
   */
  function padLeadingZeros(uint256 value, uint256 digitCount) internal pure returns (string memory paddedString) {
    paddedString = value.toString();
    for (uint256 i = bytes(paddedString).length; i < digitCount; ) {
      paddedString = string.concat("0", paddedString);
      unchecked {
        ++i;
      }
    }
  }
}