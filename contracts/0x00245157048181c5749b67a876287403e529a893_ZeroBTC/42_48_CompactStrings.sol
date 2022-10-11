// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../interfaces/CompactStringErrors.sol";

contract CompactStrings is CompactStringErrors {
  function packString(string memory unpackedString)
    internal
    pure
    returns (bytes32 packedString)
  {
    if (bytes(unpackedString).length > 31) {
      revert InvalidCompactString();
    }
    assembly {
      packedString := mload(add(unpackedString, 31))
    }
  }

  function unpackString(bytes32 packedString)
    internal
    pure
    returns (string memory unpackedString)
  {
    assembly {
      // Get free memory pointer
      let freeMemPtr := mload(0x40)
      // Increase free memory pointer by 64 bytes
      mstore(0x40, add(freeMemPtr, 0x40))
      // Set pointer to string
      unpackedString := freeMemPtr
      // Overwrite buffer with zeroes in case it has already been used
      mstore(freeMemPtr, 0)
      mstore(add(freeMemPtr, 0x20), 0)
      // Write length and name to string
      mstore(add(freeMemPtr, 0x1f), packedString)
    }
  }
}