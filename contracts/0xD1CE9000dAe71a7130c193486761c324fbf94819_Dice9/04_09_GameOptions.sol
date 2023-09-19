pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT


// Imports
import { TinyStrings, TinyString, TinyString5 } from "./TinyStrings.sol";
import { Math } from "./Math.sol";

/* GameOption is a custom type that represents a bit mask holding the outcome(s) the player has made a bet on.
 * The encoding scheme is using lower 12 bits of the integer to keep the flag indicating the
 * type of bet used along with the options chosen by the user.
 *
 * Having this as a separate type allows us to clearly bear the meaining of variables holding game options data
 * and also be less error-prone to things like implicit casts done by Solidity.
 *
 * The type's constructors defined in the library below also perform sanity checks on the values provided;
 * this way, if there is an instance of GameOptions somewhere, it is guaranteed to be valid and it is not neccessary to
 * re-validate it on the spot.
 *
 * Examples:
 *  1. Coin Flip bet on tails: 0b000000000010
 *  2. Dice bet on 1, 2 and 3: 0b010000000111
 *  3. TwoDice bet on 8 and 9: 0b100011000000
 *  4. Etheroll bet on <= 55:  0b001000110111
 */
type GameOption is uint256;

/**
 * This library provides a set of constants (like human-readable strings used for logging) along with
 * utility methods to abstract away the manipulation of GameOption custom type.
 */
library GameOptions {
  // Extension methods
  using TinyStrings for TinyString;

  // Human-readable representation of "heads" option for CoinFlip game
  TinyString5 constant internal HEADS_STR     = TinyString5.wrap(uint40(bytes5("heads")));
  // Human-readable representation of "tails" option for CoinFlip game
  TinyString5 constant internal TAILS_STR     = TinyString5.wrap(uint40(bytes5("tails")));
  // Human-readable representation of "jackpot" string
  TinyString5 constant internal JCKPT_STR     = TinyString5.wrap(uint40(bytes5("jckpt")));
  // Prefix for logging description of CoinFlip games
  TinyString constant internal COINFLIP_STR   = TinyString.wrap(uint72(bytes9("CoinFlip ")));
  // Prefix for logging description of Dice games
  TinyString constant internal DICE_STR       = TinyString.wrap(uint40(bytes5("Dice ")));
  // Prefix for logging description of TwoDice games
  TinyString constant internal TWODICE_STR    = TinyString.wrap(uint24(bytes3("2D ")));
  // Prefix for logging description of Etheroll games
  TinyString constant internal ETHEROLL_STR   = TinyString.wrap(uint88(bytes11("Etheroll <=")));

  // The mask selecting bits of GameOption containing CoinFlip choices – lower 2 bits
  uint constant internal GAME_OPTIONS_COIN_FLIP_MASK_BITS = (1 << 2) - 1;
  // The mask selecting bits of GameOption containing Dice choices – lower 6 bits
  uint constant internal GAME_OPTIONS_DICE_MASK_BITS      = (1 << 6) - 1;
  // The mask selecting bits of GameOption containing TwoDice choices – lower 11 bits
  uint constant internal GAME_OPTIONS_TWO_DICE_MASK_BITS  = (1 << 11) - 1;
  // The mask selecting bits of GameOption containing Etheroll number – lower 8 bits
  uint constant internal GAME_OPTIONS_ETHEROLL_MASK_BITS  = (1 << 8) - 1;
  // The maximum number allowed for an Etheroll game
  uint constant internal GAME_OPTIONS_ETHEROLL_MASK_MAX   = 99;

  // The flag indicating the GameOption describes a Dice game – 10th bit set
  uint constant internal GAME_OPTIONS_DICE_FLAG = (1 << 10);
  // The flag indicating the GameOption describes a TwoDice game – 11th bit set
  uint constant internal GAME_OPTIONS_TWO_DICE_FLAG = (1 << 11);
  // The flag indicating the GameOption describes an Etheroll game – 9th bit set
  uint constant internal GAME_OPTIONS_ETHEROLL_FLAG = (1 << 9);
  // The maximum value of GameOption as an integer – having higher bits set would mean there was on overflow
  uint constant internal GAME_OPTIONS_THRESHOLD = 2 ** 12;

  // The number of combinations in CoinFlip game
  uint constant internal GAME_OPTIONS_COIN_FLIP_MODULO = 2;
  // The number of combinations in Dice game
  uint constant internal GAME_OPTIONS_DICE_MODULO = 6;
  // The number of combinations in TwoDice game
  uint constant internal GAME_OPTIONS_TWO_DICE_MODULO = 36;
  // The number of combinations in Etheroll game
  uint constant internal GAME_OPTIONS_ETHEROLL_MODULO = 100;

  // The number where each hex digit represents the number of 2 dice combinations summing to a specific number
  uint constant internal GAME_OPTIONS_TWO_DICE_SUMS = 0x12345654321;
  // The number where each hex digit represents the number of dice outcomes representing a specific number (trivial)
  uint constant internal GAME_OPTIONS_DICE_SUMS = 0x111111;

  /**
   * Converts a given mask into a CoinFlip GameOption instance.
   *
   * @param mask CoinFlip choice(s) to encode.
   *
   * @return GameOption representing the passed mask.
   */
  function toCoinFlipOptions(uint mask) internal pure returns (GameOption) {
    require(mask > 0 && mask <= GAME_OPTIONS_COIN_FLIP_MASK_BITS, "CoinFlip mask is not valid");
    // CoinFlip does not have any dedicated flag set – thus simply wrap the mask
    return GameOption.wrap(mask);
  }

  /**
   * Converts a given mask into a Dice GameOption instance.
   *
   * @param mask Dice choice(s) to encode.
   *
   * @return GameOption representing the passed mask.
   */
  function toDiceOptions(uint mask) internal pure returns (GameOption) {
    require(mask > 0 && mask <= GAME_OPTIONS_DICE_MASK_BITS, "Dice mask is not valid");
    return GameOption.wrap(GAME_OPTIONS_DICE_FLAG | mask);
  }

  /**
   * Converts a given mask into a TwoDice GameOption instance.
   *
   * @param mask TwoDice choice(s) to encode.
   *
   * @return GameOption representing the passed mask.
   */
  function toTwoDiceOptions(uint mask) internal pure returns (GameOption) {
    require(mask > 0 && mask <= GAME_OPTIONS_TWO_DICE_MASK_BITS, "Dice mask is not valid");
    return GameOption.wrap(GAME_OPTIONS_TWO_DICE_FLAG | mask);
  }

  /**
   * Converts a given mask into a TwoDice Etheroll instance.
   *
   * @param option Etheroll choice to encode.
   *
   * @return GameOption representing the passed mask.
   */
  function toEtherollOptions(uint option) internal pure returns (GameOption) {
    require(option > 0 && option <= GAME_OPTIONS_ETHEROLL_MASK_MAX, "Etheroll mask is not valid");
    return GameOption.wrap(GAME_OPTIONS_ETHEROLL_FLAG | option);
  }

  /**
   * As the name suggests, the routine parses the instance of GameOption type and returns a description of what
   * kind of bet it represents.
   *
   * @param self GameOption instance to describe.
   *
   * @return numerator containing the number of choices selected in this GameOption
   *         denominator containing the total number of choices available in the game this GameOption describes
   *         bitMask containing bits set at positions where game options were selected by the player
   *         humanReadable containing an instance of TinyString describing the bet, e.g. "CoinFlip heads"
   */
  function describe(GameOption self) internal pure returns (uint numerator, uint denominator, uint mask, TinyString betDescription) {
    // we need bare underlying bits, so have to unwrap the GameOption
    uint gameOptions = GameOption.unwrap(self);

    // check if the game described in TwoDice
    if ((gameOptions & GAME_OPTIONS_TWO_DICE_FLAG) != 0) {
      // mask out the bit relevant for TwoDice game
      mask = gameOptions & GAME_OPTIONS_TWO_DICE_MASK_BITS;
      // each bit in the mask can correspond to different number of outcomes: e.g. you can 5 by rolling 1 and 4, or 4 and 1, or 3 and 2 etc.
      // to calculate the total number of rolls matching the mask, we simply multiply positions of bits set in the mask with a constant
      // containing how many combinations of 2 dice would yield a particular number
      numerator = Math.weightedPopCnt(mask, GAME_OPTIONS_TWO_DICE_SUMS);
      // denomination is always the same, 36
      denominator = GAME_OPTIONS_TWO_DICE_MODULO;
      // prepare human-readable string composed of a prefix and numbers of bits set up, with the lowest corresponding
      // to 2 (the minimum sum of 2 dice is 2), e.g. "2D 5,6,12"
      betDescription = TWODICE_STR.appendBitNumbers(mask, 2);

    // check if the game described in Dice
    } else if ((gameOptions & GAME_OPTIONS_DICE_FLAG) != 0) {
      // mask out the bit relevant for Dice game
      mask = gameOptions & GAME_OPTIONS_DICE_MASK_BITS;
      // similar to Two Dice game above, but every bit corresponding to a single option
      numerator = Math.weightedPopCnt(mask, GAME_OPTIONS_DICE_SUMS);
      // denomination is always the same, 6
      denominator = GAME_OPTIONS_DICE_MODULO;
      // prepare human-readable string composed of a prefix and numbers of bits set up, with the lowest corresponding
      // to 1 (the minimum sum of a single dice is 1), e.g. "Dice 1,2,3"
      betDescription = DICE_STR.appendBitNumbers(mask, 1);

    // check if the game described in Etheroll
    } else if ((gameOptions & GAME_OPTIONS_ETHEROLL_FLAG) != 0) {
      // mask out the bit relevant for Etheroll game
      mask = gameOptions & GAME_OPTIONS_ETHEROLL_MASK_BITS;
      // Etheroll lets players bet on a single number, stored "as in" in the mask
      numerator = mask;
      // denomination is always the same, 100
      denominator = GAME_OPTIONS_ETHEROLL_MODULO;
      // prepare human-readable string composed of a prefix and the number the player bets on, e.g. "Etheroll <=55"
      betDescription = ETHEROLL_STR.appendNumber(mask);

    // if none bits match, we are describing a CoinFlip game
    } else {
      // mask out the bit relevant for CoinFlip game
      mask = gameOptions & GAME_OPTIONS_COIN_FLIP_MASK_BITS;
      // we only let players bet on a single option in CoinFlip
      numerator = 1;
      // denomination is always the same, 2
      denominator = GAME_OPTIONS_COIN_FLIP_MODULO;
      // prepare human-readable string composed of a prefix and the side the player bets on, e.g. "CoinFlip tails"
      betDescription = COINFLIP_STR.append(mask == 1 ? HEADS_STR : TAILS_STR);
    }
  }
}