// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

/**
 * @title CRC32
 * @notice This contract implements the CRC32 checksum algorithm.
 */
library CRC32 {
  // CRC32 algorithm: https://en.wikipedia.org/wiki/Cyclic_redundancy_check
  /**
   * @dev Calculates the CRC32 checksum of a chunk of data.
   * @param self The data to calculate the checksum of.
   * @param start The start index of the data.
   * @param end The end index of the data.
   * @return checksum The CRC32 checksum of the data.
   */
  function crc32(bytes memory self, uint start, uint end) internal pure returns (uint32 checksum) {
    // Initialize the checksum to 0xffffffff
    checksum = 0xffffffff;

    // Loop through each byte of the chunk data
    for (uint i = start; i < end; i++) {
      // XOR the byte with the checksum
      checksum = checksum ^ uint8(self[i]);
      // Loop through each bit of the byte
      for (uint j = 0; j < 8; j++) {
        // If the LSB of the checksum is 1
        if ((checksum & 1) == 1) {
          // 0xEDB88320 is the CRC-32 polynomial in reversed bit order
          // this translates to the polynomial with equation
          // x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
          // which is the same as the one used in the PNG specification
          checksum = (checksum >> 1) ^ 0xedb88320;
        }
        // If the LSB of the checksum is 0
        else {
          // Shift the checksum right by 1 bit
          checksum = (checksum >> 1);
        }
      }
    }

    // Return the inverted checksum
    return ~checksum;
  }
}