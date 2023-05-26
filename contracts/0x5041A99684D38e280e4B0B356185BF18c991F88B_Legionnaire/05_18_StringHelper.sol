//SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.0;

library StringHelper {
  function substring(string memory str, uint startIndex, uint endIndex) pure internal returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
  }

  function compareStrings(string memory a, string memory b) pure internal returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }
}