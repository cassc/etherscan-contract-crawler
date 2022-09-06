// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

library StringHelper {
  function equals(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }
}