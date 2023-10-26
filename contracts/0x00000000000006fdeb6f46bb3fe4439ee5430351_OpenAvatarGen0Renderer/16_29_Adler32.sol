// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

/**
 * @title Adler32
 * @notice This contract implements the Adler32 checksum algorithm.
 */
library Adler32 {
  function adler32(bytes memory self, uint offset, uint end) internal pure returns (uint32) {
    unchecked {
      uint32 a = 1;
      uint32 b = 0;

      // Process each byte of the data in order
      for (uint i = offset; i < end; i++) {
        a = (a + uint32(uint8(self[i]))) % 65521;
        b = (b + a) % 65521;
      }

      // The Adler-32 checksum is stored as a 4-byte value
      return (b << 16) | a;
    }
  }
}