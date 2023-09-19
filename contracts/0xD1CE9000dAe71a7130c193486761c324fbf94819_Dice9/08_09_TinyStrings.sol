pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT


// Imports
import { Math } from "./Math.sol";

/**
 * TinyString is a custom type providing an alternative representation of short (up to 32 chars) strings containing
 * ASCII characters.
 *
 * We heavily use this primitive in the contract to keep human-readable logs and input parameters yet avoid overspending
 * tremendeous amount on gas.
 */
type TinyString  is uint256;

/**
 * A special case of TinyString - a string that contains a single ASCII character.
 */
type TinyString1 is uint8;

/**
 * A special case of TinyString - a string that contains 5 ASCII characters.
 */
type TinyString5 is uint40;

/**
 * The library providing functions for manipulating TinyString instances in a nice and readable way.
 */
library TinyStrings {
  // Extension functions
  using TinyStrings for TinyString;

  // The constant holding "," character
  TinyString1 constant internal COMMA = TinyString1.wrap(uint8(bytes1(",")));
  // The constant holding "+" character
  TinyString1 constant internal PLUS  = TinyString1.wrap(uint8(bytes1("+")));
  // The constant holding " " character
  TinyString1 constant internal SPACE = TinyString1.wrap(uint8(bytes1(" ")));

  // The bit mask selecting 8th bit from every byte of 32 byte integer - used to check whether a string
  // contains any characters > 128
  uint constant internal MSB_BYTES = 0x8080808080808080808080808080808080808080808080808080808080808080;
  // The code of "0" in ASCII – allows us to do super-cheap parsing by subtracting this from the charCode (1 = 49, 2 = 50 etc)
  uint constant internal ZERO_ASCII_CODE = 48;
  // How many bit there are in a single ASCII character.
  uint constant internal BITS_PER_CHARACTER = 8;
  // How many bit there are in 5 ASCII characters.
  uint constant internal BITS_PER_FIVE_CHARACTERS = BITS_PER_CHARACTER * 5;
  // The maximum possible length in bits of TinyString
  uint constant internal TINY_STRING_MAX_LENGTH = 32;
  // The maximum possible length of TinyString in bits.
  uint constant internal TINY_STRING_MAX_LENGTH_BITS = TINY_STRING_MAX_LENGTH * BITS_PER_CHARACTER;
  // Contains the bit mask selecting bits of the very last character in the TinyString - simply the lowest byte
  uint constant internal LAST_CHARACTER_MASK_BITS = 0xFF;

  // The error indicating a native string passed to the library exceeds 32 characts and cannot be manipulated.
  error StringTooLong();
  // The error indicating a string contains non-ASCII charactes and cannot be manipulated by the library.
  error NotAscii();

  /**
   * Converts an instance of TinyString into a native string placed in memory so that it can be used in
   * logs and other places requiring native string instances.
   *
   * @param self the instance of TinyString to convert into a native one.
   *
   * @return result the native string instance containing all characters from the TinyString instance.
   */
  function toString(TinyString self) internal pure returns (string memory result) {
    // convert the string into an integer
    uint tinyString = TinyString.unwrap(self);
    // calculate the length of the string using the Math library: the length of the string would be
    // equivalent to the number of highest bit set divied by 8 (since every character occupy 8 bits) and
    // rounded up to nearest multiple of 8.
    uint length = Math.getBitLength8(tinyString);

    // Allocate a string in memory (divide the length by 8 since it is in bits and we need bytes)
    result = new string(length >> 3);

    // Copy over character data (situated right after a 32-bit length prefix)
    assembly {
      // we need to shift the bytes so that the characters reside in the higher bits, with lower set to 0
      length := sub(256, length)
      tinyString := shl(length, tinyString)
      // once we shifted the characters, simply copy the memory over
      mstore(add(result, 32), tinyString)
    }
  }

  /**
   * Converts a native string into a TinyString instance, performing all required validity checks
   * along the way.
   *
   * @param self a native string instance to convert into TinyString.
   *
   * @return tinyString an instance of the TinyString type.
   */
  function toTinyString(string calldata self) internal pure returns (TinyString tinyString) {
    // first off, make sure the length does not exceed 32 bytes, since it is the maximum length a
    // TinyString can store being backed by uint256
    uint length = bytes(self).length;
    if (length > TINY_STRING_MAX_LENGTH) {
      // the string is too long, we have to crash.
      revert StringTooLong();
    }

    // start unchecked block since we know that length is within [0..32] range
    unchecked {
      // copying the memory from native string would fill higher bits first, but we want
      // TinyString to contain characters in the lowest bits; thus, we need to compute the number
      // of bits to shift the data so that bytes like 0xa000 end up 0xa.
      uint shift = TINY_STRING_MAX_LENGTH_BITS - (length << 3);

      // Using inline assembly to efficiently fetch character data in one go.
      assembly {
        // simply copy the memory over (we have validated the length already, so all is good)
        tinyString := calldataload(self.offset)
        // shift the bytes to make sure the data sits in lower bits
        tinyString := shr(shift, tinyString)
      }
    }

    // Check that string contains ASCII characters only - i.e. there are no bytes with the value of 128+
    if (TinyString.unwrap(tinyString) & MSB_BYTES != 0) {
      // there are non-ascii characters – we have to crash
      revert NotAscii();
    }
  }

  /**
   * Reads the last character of the string and classifies it as a digit or a non-digit one.
   *
   * If the string is empty, it would return a tuple of (false, -48).
   *
   * @param self an instance of TinyString to get the last character from.
   *
   * @return isDigit flag set to true if the character is a digit (0..9).
   *         digit the actual digit value of the charact (valid only is isDigit is true).
   */
  function getLastChar(TinyString self) internal pure returns (bool isDigit, uint digit) {
    // we are operating on a single-byte level and thus do not need integer overflow checks
    unchecked {
      // get the lowest byte of the string
      uint charCode = TinyString.unwrap(self) & LAST_CHARACTER_MASK_BITS;

      // compute the digit value, which is simply charCode - 48
      digit = charCode - ZERO_ASCII_CODE;
      // indicate whether the character is a digit (falls into 0..9 range)
      isDigit = digit >= 0 && digit < 10;
    }
  }

  /**
   * Checks whether the string contains any characters.
   *
   * @param self an instance of TinyString to check for emptiness.
   *
   * @return true if the string is empty.
   */
  function isEmpty(TinyString self) internal pure returns (bool) {
    // as simple as it gets: if there are no characters, the string will be 0x0
    return TinyString.unwrap(self) == 0;
  }

  /**
   * Returns a copy of TinyString instance without the last character.
   *
   * @param self an instance of TinyString to remove the last character from.
   *
   * @return a new instance of TinyString.
   */
  function chop(TinyString self) internal pure returns (TinyString) {
    // we simply right-shift all the bytes by 8 bits – and that effectively deletes the last character.
    return TinyString.wrap(TinyString.unwrap(self) >> BITS_PER_CHARACTER);
  }

  /**
   * Returns a copy of TinyString instance with TinyString1 attached at the end.
   *
   * @param self an instance of TinyString to append the TinyString1 to.
   * @param chunk an instance of TinyString1 to append.
   *
   * @return a new instance of TinyString.
   */
  function append(TinyString self, TinyString1 chunk) internal pure returns (TinyString) {
    // we just left-shift the string and OR with the TinyString1 chunk to copy its character over into the lowest byte.
    return TinyString.wrap((TinyString.unwrap(self) << BITS_PER_CHARACTER) | TinyString1.unwrap(chunk));
  }

  /**
   * Returns a copy of TinyString instance with TinyString1 attached at the end.
   *
   * @param self an instance of TinyString to append the TinyString1 to.
   * @param chunk an instance of TinyString1 to append.
   *
   * @return a new instance of TinyString.
   */
  function append(TinyString self, TinyString5 chunk) internal pure returns (TinyString) {
    // we just left-shift the string and OR with the TinyString5 chunk to copy its characters over into the lowest bytes.
    return TinyString.wrap((TinyString.unwrap(self) << BITS_PER_FIVE_CHARACTERS) | TinyString5.unwrap(chunk));
  }

  /**
   * Checks whether TinyString contains the same characters as TinyString5.
   *
   * @param self an instance of TinyString to check.
   * @param other an instance of TinyString5 to check.
   *
   * @return true if the strings are the same.
   */
  function equals(TinyString self, TinyString5 other) internal pure returns (bool) {
    return TinyString.unwrap(self) == TinyString5.unwrap(other);
  }

  /**
   * Appends a number to an instance of a TinyString: "1 + 2 = ".toTinyString().append(3) => "1 + 2 = 3".
   *
   * @param self an instance of TinyString to append the number to.
   * @param number the number to append.
   *
   * @return a new instance of TinyString.
   */
  function appendNumber(TinyString self, uint number) internal pure returns (TinyString) {
    // since we work on character level, we don't need range checks.
    unchecked {
      uint str = TinyString.unwrap(self);

      if (number >= 100) {
        // if number is > 100, append number of hundreds
        str = (str << BITS_PER_CHARACTER) | (ZERO_ASCII_CODE + number / 100);
      }

      if (number >= 10) {
        // if number is > 100, append number of tens
        str = (str << BITS_PER_CHARACTER) | (ZERO_ASCII_CODE + number / 10 % 10);
      }

      // append any remainder (0..9) to the string
      return TinyString.wrap((str << BITS_PER_CHARACTER) | (ZERO_ASCII_CODE + number % 10));
    }
  }

  /**
   * Appends the numbers of bits set in the mask, naming them from startNumber.
   *
   * This is a very specific method that allows us to easily compose strings like "Dice 1,2,5", where 1,2,5 portion
   * is coming from a bit mask.
   *
   * startNumber parameter is required so that every bit of the mask is named properly (i.e. in Dice game the lowest
   * bit represents an outcome of 1, whereas in TwoDice game the lowest bit means 2).
   *
   * @param self an instance of TinyString to append the bit numbers to.
   * @param mask the mask to extract bits from to append to the string.
   * @param startNumber the value of the lowest bit in the mask.
   *
   * @return a new instance of TinyString.
   */
  function appendBitNumbers(TinyString self, uint mask, uint startNumber) internal pure returns (TinyString) {
    // repeat while the mask is not empty
    while (mask != 0) {
      // check if the lowest bit is set
      if (mask & 1 != 0) {
        // it is set – append current value of startNumber to the string and add a ","
        self = self.appendNumber(startNumber).append(TinyStrings.COMMA);
      }

      // right-shift the mask to start considering the next bit
      mask >>= 1;
      // increment the number since the next bit is one higher than the previous one. we don't check for overflows here
      // since the loop is guaranteed to end in at most 256 iterations anyway
      unchecked {
        startNumber++;
      }
    }

    // remove the last character since every bit appends "," after its number
    return self.chop();
  }
}