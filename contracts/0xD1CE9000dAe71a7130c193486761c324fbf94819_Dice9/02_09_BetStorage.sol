pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT


// Imports
import { Math } from "./Math.sol";
import { GameOption, GameOptions } from "./GameOptions.sol";
import { PackedBet, PackedBets } from "./PackedBets.sol";

/**
 * The library provides abstractions to manage contract's bets storage in a code-friendly way.
 *
 * The main idea behind the routines is to abuse the fact that a single PackedBet occupies 32 bytes, meaining
 * that the contract can store 8 of those in a single storage slot. Squeezing multiple bets into a single slots
 * allows to save on gas tremendeously and requires just a handful of helper routines to make it transparent to the
 * outer contract.
 *
 * The library exports a struct called Bets that is designed to keep track of players' bets – an instance of this structre,
 * along with "storage" modifier, is required to invoke libraries' functions.
 */
library BetStorage {
  // Extension functions
  using PackedBets for PackedBet;

  /**
   * The structure defining mappings to keep track of players' bets.
   * it keeps two separate mappings, one for tracking player nonces (seq numbers of bets being placed),
   * the other holds the data itself.
   */
  struct Bets {
    mapping (address => uint) playerNoncesBy8;
    mapping (address => mapping (uint => uint)) playerBets;
  }

  // The bit to be set in playerNoncesBy8 mapping to disable accepting bets from an address
  uint constant internal PLAYER_NONCE_ACCOUNT_BANNED_BIT = 1;
  // The bit mask selecting the bits so that the number would turn into number mod 8
  uint constant internal PLAYER_NONCE_MOD8_MASK = uint(0x7);
  // The number of bits to shift the number to divide or multiply by 32 (log2(32))
  uint constant internal MULTIPLY_BY_32_BIT_SHIFT = 5;
  // The bit mask selecting exactly PackedBets.PACKED_BET_LENGTH bits
  uint constant internal PACKED_BET_MASK = 2 ** PackedBets.PACKED_BET_LENGTH - 1;
  // The bit mask selecting the bits so that the number would turn into number div 8
  uint constant internal PLAYER_NONCE_DIV8_MASK = ~PLAYER_NONCE_MOD8_MASK;
  // The number of packed bets stored in a single storage slot
  uint constant internal PACKED_BETS_PER_SLOT = 8;

  // The bit mask selecting bits from 8 possible PackedBets stored in a single slot. ANDing the slot value with
  // this constant allows for quick checks of whether there any PackedBets with non-zero amounts in this slot.
  uint constant internal ALL_QUANT_AMOUNTS_MASK =
    PackedBets.QUANT_AMOUNT_MASK |
    PackedBets.QUANT_AMOUNT_MASK << (PackedBets.PACKED_BET_LENGTH * 1) |
    PackedBets.QUANT_AMOUNT_MASK << (PackedBets.PACKED_BET_LENGTH * 2) |
    PackedBets.QUANT_AMOUNT_MASK << (PackedBets.PACKED_BET_LENGTH * 3) |
    PackedBets.QUANT_AMOUNT_MASK << (PackedBets.PACKED_BET_LENGTH * 4) |
    PackedBets.QUANT_AMOUNT_MASK << (PackedBets.PACKED_BET_LENGTH * 5) |
    PackedBets.QUANT_AMOUNT_MASK << (PackedBets.PACKED_BET_LENGTH * 6) |
    PackedBets.QUANT_AMOUNT_MASK << (PackedBets.PACKED_BET_LENGTH * 7);

  // The number indicating the slot is full with bets, i.e. all 8 spots are occupied by instances of PackedBet. The check is based
  // on the fact that we fill up the slot from left to right, meaning that placing the 8th PackedBet into a slot will set some bits higher than 224th one.
  uint constant internal FULL_SLOT_THRESHOLD = PackedBets.QUANT_AMOUNT_THRESHOLD << (PackedBets.PACKED_BET_LENGTH * 7);

  // An error indicating the player's address is not allowed to place the bets
  error AccountSuspended();

  /**
   * Being given the storage-located struct, the routine places PackedBet instance made by a player into a spare slot
   * and returns this bet's playerNonce - a seq number of the bet made by the player against this instance of the contract.
   *
   * @param bets the instance of Bets struct to manipulate.
   * @param player the address of the player placing the bet.
   * @param packedBet the instance of the PackedBet to place.
   *
   * @return playerNonce the seq number of the bet made by this player.
   */
  function storePackedBet(Bets storage bets, address player, PackedBet packedBet) internal returns (uint playerNonce) {
    // first off, read the current player's nonce. We are storing the nonces in 8 increments to avoid
    // unneccessary storage operations – in any case, each storage slot contains 8 bets, so we only need to know
    // the number / 8 to operate.
    uint playerNonceBy8 = bets.playerNoncesBy8[player];

    // if the PLAYER_NONCE_ACCOUNT_BANNED_BIT bit is set, it means we do not want to accept the bets from this player's address
    if (playerNonceBy8 & PLAYER_NONCE_ACCOUNT_BANNED_BIT != 0) {
      revert AccountSuspended();
    }

    // read the current slot being
    uint slot = bets.playerBets[player][playerNonceBy8];

    // identify how many 32 bit chunks (i.e. PackedBet) are already stored there
    uint betOffsetInSlot = Math.getBitLength32(slot);
    // divide this number by 32 (to get from bit offsets to actual number)
    uint playerNonceMod8 = betOffsetInSlot >> MULTIPLY_BY_32_BIT_SHIFT;

    // modify the slot by placing the current bet into the spare space – shift the data by freeShift value to achieve this
    slot |= (packedBet.toUint() << betOffsetInSlot);

    // update the slot in the storage
    bets.playerBets[player][playerNonceBy8] = slot;

    // IMPORTANT: did we just take the last available spot in the slot?
    if (playerNonceMod8 == (PACKED_BETS_PER_SLOT - 1)) {
      // if we did, update the player's nonce so that next bets would write to the new slot
      bets.playerNoncesBy8[player] = playerNonceBy8 + PACKED_BETS_PER_SLOT;
    }

    // return full value of player's nonce
    playerNonce = playerNonceBy8 + playerNonceMod8;
  }

  /**
   * Being given the storage-located struct, the routine extracts a bet from the storage.
   *
   * Extracting the bet means the corresponding part of the storage slot is modified so that the amount kept in
   * corresponding PackedBet entry is reset to 0 to indicate the bet has been proccessed.
   *
   * Once ALL of the bets in a slot are marked as processed, the slot is cleared to become 0, allowing us to reclaim a
   * bit of gas.
   *
   * @param bets the instance of Bets struct to manipulate.
   * @param player the address of the player placing the bet.
   * @param playerNonce the playerNonce to read from the storage.
   *
   * @return the instance of the PackedBet found in the corresponding slot; might be 0x0 if missing.
   */
  function ejectPackedBet(Bets storage bets, address player, uint playerNonce) internal returns (PackedBet) {
    // compute the playerNonce div 8 – that's the nonce value we use in the store (see storePackedBet)
    uint playerNonceBy8 = playerNonce & PLAYER_NONCE_DIV8_MASK;
    // compute the position of the bet in the slot – it's offset by N PackedBet places, where N = playerNonce mod 8
    uint betOffsetInSlot = (playerNonce & PLAYER_NONCE_MOD8_MASK) << MULTIPLY_BY_32_BIT_SHIFT;

    // read the current slot's value
    uint slot = bets.playerBets[player][playerNonceBy8];

    // read the specific PackedBet, ANDing with PACKED_BET_MASK to avoid integer overflows
    uint data = (slot >> betOffsetInSlot) & PACKED_BET_MASK;

    // compute the positions of the bits where the amount value for the current bet is stored – it is simply
    // QUANT_AMOUNT_MASK shifted into the position of the PackedBet instance within the slot.
    uint amountZeroMask = ~(PackedBets.QUANT_AMOUNT_MASK << betOffsetInSlot);

    // clear up the bits corresponding to amount of our packed bet, essentially clearing the amount down to 0
    slot &= amountZeroMask;

    // check if all the spots in the slot contain 0s in amount AND if the slot is full...
    if (((slot & ALL_QUANT_AMOUNTS_MASK) == 0) && (slot >= FULL_SLOT_THRESHOLD)) {
      // delete the slot's data to get some gas refunded
      slot = 0;
    }

    // update the storage
    bets.playerBets[player][playerNonceBy8] = slot;

    // produce a PackedBet instance by wrapping the data. Since the data comes from the contract storage, and this library is the
    // only one that writes it, we do not need to perform additional validations here
    return PackedBet.wrap(data);
  }

  /**
   * Marks the entry in playerNonce with a flag indicating this player address should not be allowed to place new bets.
   *
   * @param bets the instance of Bets struct to manipulate.
   * @param player the address of the player placing the bet.
   * @param suspend whether to suspend or un-suspend the player.
   */
  function suspendPlayer(Bets storage bets, address player, bool suspend) internal {
    if (suspend) {
      // set 1st bit on the nonce counter
      bets.playerNoncesBy8[player] |= PLAYER_NONCE_ACCOUNT_BANNED_BIT;
    } else {
      // clear 1st bit from the nonce counter
      bets.playerNoncesBy8[player] &= ~PLAYER_NONCE_ACCOUNT_BANNED_BIT;
    }
  }
}