pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT


// Imports
import { Math } from "./Math.sol";
import { TinyStrings, TinyString } from "./TinyStrings.sol";
import { GameOptions } from "./GameOptions.sol";

/**
 * The library providing helper method to parse user input from a TinyString instance.
 */
library Options {
  // Extension functions
  using TinyStrings for TinyString;

  // The error indicating the option found within a string falls out of min...max range.
  error OptionNotInRange(uint option, uint min, uint max);

  /**
   * Being given an instance of TinyString and min/max constraints, parses the string returning
   * the last found option as an integer as well as bit mask with bits set at places corresponding
   * to the numbers found in the string.
   *
   * If the string is "heads" or "tails", it is instantly considered a CoinFlip option description,
   * returning hardcoded values for the mask and option parameters.
   *
   * The string is considered to consist of digits separated by non-digits characters. To save the gas,
   * the function does not distinguish between the types of separators; any non-digit character is considered
   * a separator.
   *
   * Examples:
   *  1. "heads" -> (1, 0)
   *  2. "tails" -> (2, 1)
   *  3. "1" -> (0b1, 1)
   *  4. "1,2,3" -> (0b111, 3)
   *
   * @param tinyString an instance of TinyString to parse.
   * @param min the minimum allowed number.
   * @param max the maximum allowed number.
   *
   * @return mask the bit mask where the bit is set if the string contains such a number
   *         lastOption the last found number.
   */
  function parseOptions(TinyString tinyString, uint min, uint max) internal pure returns (uint mask, uint lastOption) {
    // fast track: is the string "heads"?
    if (tinyString.equals(GameOptions.HEADS_STR)) {
      return (1, 0);
    }

    // fast track: is the string "tails"?
    if (tinyString.equals(GameOptions.TAILS_STR)) {
      return (2, 1);
    }

    // we parse the string left-to-right, meaning the first digit of a number has to be multipled by 1, the second by 10 etc
    uint digitMultiplier = 1;

    // we run the whole loop without arithmetic checks since we only use
    // functions operating on heavily constrained values
    unchecked {
      // repeat until stopped explicitly
      while (true) {
        // classify the last character.
        // IMPORTANT: empty string would return isDigit = false
        (bool isDigit, uint digit) = tinyString.getLastChar();

        // is the last character a digit?
        if (isDigit) {
          // is it the first digit of a new number? if so, reset the lastOption to 0
          lastOption = digitMultiplier == 1 ? 0 : lastOption;
          // add the digit multiplied by current multiplier to the lastOption value
          lastOption += digitMultiplier * digit;
          // the next digit would be 10x
          digitMultiplier *= 10;
        } else {
          // we stumbled upon a separator OR an empty string – let's validate the computed number
          if (lastOption < min || lastOption > max) {
            // the number falls out of min..max range, we have to crash
            revert OptionNotInRange(lastOption, min, max);
          }

          // set the bit corresponding to the last found number
          mask |= 1 << (lastOption - min);
          // reset the digit multiplier to 1 (since the next number will be a new number)
          digitMultiplier = 1;
        }

        // is the string empty?
        if (tinyString.isEmpty()) {
          // it is – stop the loop, we are done
          break;
        }

        // remove the last character from the string and repeat
        tinyString = tinyString.chop();
      }
    }
  }
}