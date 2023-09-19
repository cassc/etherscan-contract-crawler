pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT


// Imports
import { Math } from "./Math.sol";
import { GameOption, GameOptions } from "./GameOptions.sol";

/**
 * PackedBet is a custom type that represents a single bet placed by a player. It encodes the bet amount
 * (quantized down to a specific increment to save space), the GameOption instance (see ./GameOptions.sol) and
 * the bit indicating whether the bet was nominated to play for a jackpot.
 *
 * The memory layout of the type if pretty straightforward:
 * 1. Lowest 16 bits hold bet amount (divided by quant constant)
 * 2. Bit #17 is set to 1 if the bet plays for a jackpot
 * 3. Bits #18-29 hold GameOption data
 * 4. Bits #30-32 hold bet time (mod 4 hours).
 *
 * The type's constructors defined in the library below also perform sanity checks on the values provided;
 * this way, if there is an instance of PackedBet somewhere, it is guaranteed to be valid and it is not neccessary to
 * re-validate it on the spot.
 */
type PackedBet is uint256;

/**
 * The library containing conversion routines (to pack and unpack bet data into an instance of PackedBet),
 * as well as basic utilities to compute certain attributes of a PackedBet.
 */
library PackedBets {
  // Extension functions
  using Math for bool;

  // The byte length of the PackedBet type
  uint constant internal PACKED_BET_LENGTH = 32;
  // The length of the epoch for our contract (4 hours)
  uint constant internal EPOCH_LENGTH = 4 * 3600;
  // The bit mask selecting the bits allocated to hold quantified amount of the bet
  uint constant internal QUANT_AMOUNT_MASK = QUANT_AMOUNT_THRESHOLD - 1;
  // The bit mask selecting the bits allocated to hold GameOption data (not shifted)
  uint constant internal GAME_OPTIONS_MASK = GameOptions.GAME_OPTIONS_THRESHOLD - 1;
  // The maximum amount after quanitification (to avoid bit overflow)
  uint constant internal QUANT_AMOUNT_THRESHOLD = 2 ** 17;
  // The bit mask selecting all the data but epoch number
  uint constant internal ALL_BUT_EPOCH_BITS = 2 ** 30 - 1;
  // The value by which we quantify the bets
  uint constant internal QUANT_STEP = 0.001 ether;
  // The bit number where isJackpot flag is stored
  uint constant internal JACKPOT_BIT_OFFSET = 17;
  // The bit mask selecting bit representing isJackpot flag (shifted).
  uint constant internal JACKPOT_MASK = 1 << JACKPOT_BIT_OFFSET;
  // The bit number where GameOption data starts
  uint constant internal GAME_OPTIONS_BIT_OFFSET = 18;
  // The bit number where epoch number data starts
  uint constant internal EPOCH_BIT_OFFSET = 30;
  // The modulo of the epoch number – we only keep 3 bits of epoch number along with the bets
  uint constant internal EPOCH_NUMBER_MODULO = 4;
  // The bit mask selecting bits for epoch number
  uint constant internal EPOCH_NUMBER_MODULO_MASK = 3;

  /**
   * Packs the given amount (in wei), GameOption instance and a jackpot flag into a instance of a PackedBet.
   *
   * The routine assumes GameOption passed to it is valid and does not perform any additional checks.
   *
   * The routine checks that amount does not exceed maximum allowed one and is also an exact multiple of QUANT_STEP,
   * to avoid situations where 0.0011 Ethers are wagered and trimmed down to 0.001 in further calculations – it would
   * crash otherwise.
   *
   * @param amount the amount of wei being wagered.
   * @param gameOptions the instance of GameOption to encode.
   * @param isJackpot the flag inidicating the jackpot participation.
   *
   * @return an instance of PackedBet representing all the data passed.
   */
  function pack(uint amount, GameOption gameOptions, bool isJackpot) internal view returns (PackedBet) {
    // calculate quantified amount and the reminder
    uint quantAmount = amount / QUANT_STEP;
    uint quantReminder = amount % QUANT_STEP;

    // make sure the quantAmount does not overflow allowed size and that the reminder is 0
    require(quantAmount != 0 && quantAmount < QUANT_AMOUNT_THRESHOLD && quantReminder == 0, "Bet amount not quantifiable");

    // take 3 lowest of the current epoch number to keep it along with the PackedBet
    uint epochMod4 = getCurrentEpoch() & EPOCH_NUMBER_MODULO_MASK;

    // construct the packed bet by:
    // 1. Storing the epoch number in bits 30..32
    // 2. Storing GameOption in bits 18...29
    // 3. Storing isJackpot in bit 17
    // 4. Storing quantAmount in bits 0..16
    uint packedBet =  epochMod4 << EPOCH_BIT_OFFSET |
                      GameOption.unwrap(gameOptions) << GAME_OPTIONS_BIT_OFFSET |
                      isJackpot.toUint() << JACKPOT_BIT_OFFSET |
                      quantAmount;

    return PackedBet.wrap(packedBet);
  }

  /**
   * Checks if the PackedBet instance is empty (does not contain anything).
   *
   * @param self PackedBet instance to check.
   *
   * @return true if the PackedBet instance is empty.
   */
  function isEmpty(PackedBet self) internal pure returns (bool) {
    return PackedBet.unwrap(self) == 0;
  }

  /**
   * Converts the PackedBet to an integer representation.
   *
   * @param self PackedBet instance to convert into an integer.
   *
   * @return the number representing the PackedBet instance.
   */
  function toUint(PackedBet self) internal pure returns (uint256) {
    return PackedBet.unwrap(self);
  }

  /**
   * Removes all the bits encoding epoch number from the instance of the PackedBet.
   * This routine is helpful when two PackedBets need to be checked for equality.
   *
   * @param self the instance of the PackedBet to remove epoch number from.
   *
   * @return an instance of the PackedBet with epoch bits set to 0.
   */
  function withoutEpoch(PackedBet self) internal pure returns (PackedBet) {
    return PackedBet.wrap(PackedBet.unwrap(self) & ALL_BUT_EPOCH_BITS);
  }

  /**
   * Returns the number of the current and bet's epochs mod 4.
   *
   * @param self PackedBet instance to check.
   *
   * @return betEpoch the bet's epoch mod 4
   *         currentEpoch the current epoch mod 4
   */
  function extractEpochs(PackedBet self) internal view returns (uint betEpoch, uint currentEpoch) {
    // get current epoch % 4 value
    currentEpoch = getCurrentEpoch() & EPOCH_NUMBER_MODULO_MASK;
    // get bet's epoch % 4 value
    betEpoch = (PackedBet.unwrap(self) >> EPOCH_BIT_OFFSET) & EPOCH_NUMBER_MODULO_MASK;
  }

  /**
   * Checks if two PackedBet instances are exactly equal.
   *
   * @param self first instance of the PackedBet.
   * @param other second instance of the PackedBet.
   *
   * @return true if the instances are exactly the same.
   */
  function equals(PackedBet self, PackedBet other) internal pure returns (bool) {
    return PackedBet.unwrap(self) == PackedBet.unwrap(other);
  }

  /**
   * Checks if the PackedBet instance has 0 in the amount portion. This is needed to make
   * sure we don't settle the same bet twice (upon resolving a bet we clear the amount bits).
   *
   * @param self the instance of the PackedBet to check.
   *
   * @return true if the amount portion of the PackedBet is zero.
   */
  function hasZeroAmount(PackedBet self) internal pure returns (bool) {
    return (PackedBet.unwrap(self) & QUANT_AMOUNT_MASK) == 0;
  }

  /**
   * Unpacks the PackedBet instance into separate values of GameOption, amount used and isJackpot flag.
   *
   * @param self PackedBet to unpack.
   *
   * @return gameOptions the instance of GameOption encoded in this packed bet.
   *         amount the amount encoded, multiplied by quantification coefficient.
   *         isJackpot the flag indicating whether the bet plays for jackpot.
   */
  function unpack(PackedBet self) internal pure returns (GameOption gameOptions, uint amount, bool isJackpot) {
    // we need raw bits, so have to unwrap the bet into an integer
    uint data = PackedBet.unwrap(self);

    // the amount is essentially quantAmount times QUANT_STEP
    amount = (data & QUANT_AMOUNT_MASK) * QUANT_STEP;
    isJackpot = (data & JACKPOT_MASK) != 0;
    gameOptions = GameOption.wrap((data >> GAME_OPTIONS_BIT_OFFSET) & GAME_OPTIONS_MASK);
  }

  /**
   * Returns the number of the current epoch, expressed as the number of 4 hour interval since the beginning of times.
   *
   * @return the number of the curret epoch.
   */
  function getCurrentEpoch() private view returns (uint) {
    return block.timestamp / EPOCH_LENGTH;
  }
}