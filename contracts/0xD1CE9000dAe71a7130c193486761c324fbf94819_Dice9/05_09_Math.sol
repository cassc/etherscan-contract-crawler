pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT


/**
 * Tiny library containing bespoke mathematical functions allowing us to express contract's logic
 * in a more clear and gas efficient way.
 */
library Math {
  // Maximum number represented by 128 bit uint
  uint constant internal MAX128 = 2**128 - 1;
  // Maximum number represented by 64 bit uint
  uint constant internal MAX64  = 2**64  - 1;
  // Maximum number represented by 32 bit uint
  uint constant internal MAX32  = 2**32  - 1;
  // Maximum number represented by 16 bit uint
  uint constant internal MAX16  = 2**16  - 1;
  // Maximum number represented by 8 bit uint
  uint constant internal MAX8   = 2**8   - 1;

  /**
   * Returns the number of bits set rounded up to the nearest multiple of 32 – essentially,
   * how many whole 4 byte words are required to "fit" the number.
   *
   * @param number the number to compute the bit length for.
   *
   * @return length the bit length, rounded up to 32.
   */
  function getBitLength32(uint number) internal pure returns (uint length) {
    // if the number is greater than 2^128, then it is at least 128 bits long
    length  = toUint(number > MAX128) << 7;
    // if the left-most remaining part is greater than 2^64, then it's at least 64 bits longer
    length |= toUint((number >> length) > MAX64) << 6;
    // if the left-most remaining part is greater than 2^32, then it's at least 32 bits longer
    length |= toUint((number >> length) > MAX32) << 5;

    unchecked {
      // if there are more bits remaining, then it's at least another 32 bits longer (effectively, ceil())
      length += toUint((number >> length) > 0) << 5;
    }
  }

  /**
   * Returns the number of bits set rounded up to the nearest multiple of 8 – essentially,
   * how many whole 8-bit bytes are required to "fit" the number.
   *
   * @param number the number to compute the bit length for.
   *
   * @return length the bit length, rounded to 8.
   */
  function getBitLength8(uint number) internal pure returns (uint length) {
    // please refer to the explanation of getBitLength32() - the below is similar,
    // it just operates in 8 bit increments instead of 32, resulting in two extra steps.
    length  = toUint(number > MAX128) << 7;
    length |= toUint((number >> length) > MAX64) << 6;
    length |= toUint((number >> length) > MAX32) << 5;
    length |= toUint((number >> length) > MAX16) << 4;
    length |= toUint((number >> length) >  MAX8) << 3;

    unchecked {
      length += toUint((number >> length) > 0) << 3;
    }
  }

  /**
   * Returns 1 for true and 0 for false, as simle as that.
   *
   * @param boolean the bool to convert into an integer.
   * @return integer an integer of 0 or 1.
   */
  function toUint(bool boolean) internal pure returns (uint integer) {
    // As of Solidity 0.8.14, conditionals like (boolean ? 1 : 0) are not
    // optimized away, thus inline assembly forced cast is needed to save gas.
    assembly {
      integer := boolean
    }
  }

  /**
   * Returns true if a number is an exact power of 2.
   *
   * @param number the number to test for 2^N
   *
   * @return true if the number is an exact power of 2 and is not 0.
   */
  function isPowerOf2(uint number) internal pure returns (bool) {
    unchecked {
      return ((number & (number - 1)) == 0) && (number != 0);
    }
  }

  /**
   * Returns the minimum of 2 numbers.
   *
   * @param a the first number.
   * @param b the second number.
   *
   * @return a if it's not greater than b, b otherwise.
   */
  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  /**
   * Returns the maximum of 2 numbers.
   *
   * @param a the first number.
   * @param b the second number.
   *
   * @return a if it's not greater than b, b otherwise.
   */
  function max(uint a, uint b) internal pure returns (uint) {
    return a < b ? b : a;
  }

  /**
   * Multiplies every set bit's number from mask with a hex digit of the second parameter.
   * This allows us to easily count the number of bits set (by providing weightNibbles of 0x1111...)
   * or to perform a "weighted" population count, where each bit has its own bespoke contribution.
   *
   * A real-life example would be to count how many combinations of 2 dice would yield one of
   * chosen in the mask. Consider the mask of 0b1011 (we bet on 2, 3 and 5) and the weightNibbles
   * set to be 0x12345654321 (2 is only 1+1, 3 is either 1+2 or 2+1 and so on). Calling this function
   * with the above arguments would return 7 - as there 7 combinations of 2 dice outcomes that would
   * yield either 1, 2 or 4.
   *
   * @param mask the number to get set bits from.
   * @param weightNibbles the number to get multiplier from.
   *
   * @return result the sum of bit position multiplied by custom weight.
   */
  function weightedPopCnt(uint mask, uint weightNibbles) internal pure returns (uint result) {
    result = 0;

    // we stop as soon as weightNibbles is zeroed out
    while (weightNibbles != 0) {
      // check if the lowest bit is set
      if ((mask & 1) != 0) {
        // it is – add the lowest hex octet from the nibbles
        result += weightNibbles & 0xF;
      }

      // shift the mask to consider the next bit
      mask >>= 1;
      // shift the nibbles to consider the next octet
      weightNibbles >>= 4;
    }
  }
}