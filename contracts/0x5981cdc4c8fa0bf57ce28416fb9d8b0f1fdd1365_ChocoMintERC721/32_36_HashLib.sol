// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library HashLib {
  function hashBytesArray(bytes[] memory data) internal pure returns (bytes32) {
    uint256 length = data.length;
    bytes32[] memory result = new bytes32[](length);
    for (uint256 i = 0; i < length; i++) {
      result[i] = keccak256(abi.encodePacked(data[i]));
    }
    return keccak256(abi.encodePacked(result));
  }
}