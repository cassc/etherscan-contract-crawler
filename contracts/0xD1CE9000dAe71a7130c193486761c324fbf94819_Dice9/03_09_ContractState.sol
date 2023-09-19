pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT


// Imports
import { Math } from "./Math.sol";

/**
 * The library provides an abstraction to maintain the summary state of the contract.
 *
 * The main idea is to aggregate all frequently accessed parameters into a structure called State
 * which occupies a single 256-bit slot. Frequent mutations on it are performed in memory and only the
 * final result is committed to storage.
 *
 * State also conveniently packs almost all information that is needed to compute locked amounts.
 */
library ContractState {
  // Extension functions.
  using Math for bool;

  // A single 256-bit slot summary state structure. Custom sizes of the member fields are required for packing.
  struct State {
    // The total number of funds potentially due to be paid if all pending bets win
    uint96 lockedInBets;
    // The number of not-yet-settled bets that are playing for jackpot
    uint48 jackpotBetCount;
    // The value indicating the maximum potential win a bet is allowed to make. We have to cap that value to avoid
    // draining the contract in a single bet by whales who put huge bets for high odds.
    uint80 maxProfit;
    // The multiplier of the jackpot payment, set by the house.
    uint32 jackpotMultiplier;
  }

  // The maximum number of jackpot bets to consider when testing for locked funds.
  uint constant internal JACKPOT_LOCK_COUNT_CAP = 5;

  /**
   * Adding a new lock to prevent overcommitting to what the contract can't settle in worst case.
   *
   * @param lockedAmount newly locked amount.
   * @param playsForJackpot whether to account for a potential jackpot win.
   */
  function lockFunds(State memory self, uint lockedAmount, bool playsForJackpot) internal pure {
    // add the potential win to lockedInBets so that the contract always knows how much it owns in the worst case
    self.lockedInBets += uint96(lockedAmount);
    // increment the number of bets playing for a Jackpot to keep track of those too
    self.jackpotBetCount += uint48(playsForJackpot.toUint());
  }

  /**
   * Remove the lock after the bet have been processed (settled/refunded).
   *
   * @param lockedAmount locked amount.
   * @param playsForJackpot whether it was a potential jackpot win.
   */
  function unlockFunds(State memory self, uint lockedAmount, bool playsForJackpot) internal pure {
    // remove the potential win from jackpot
    self.lockedInBets -= uint96(lockedAmount);
    // ... and decrease the jackpot bet count to reduce the jackpot locked amount as well
    self.jackpotBetCount -= uint48(playsForJackpot.toUint());
  }

  /**
   * Remove the lock after the bet have been processed (settled/refunded). Direct storage access.
   *
   * @param lockedAmount locked amount.
   * @param playsForJackpot whether it was a potential jackpot win.
   */
  function unlockFundsStorage(State storage self, uint lockedAmount, bool playsForJackpot) internal {
    self.lockedInBets -= uint96(lockedAmount);
    self.jackpotBetCount -= uint48(playsForJackpot.toUint());
  }

  /**
   * Computes the total value the contract currently owes to players in case all the pending bets resolve as winning ones.
   *
   * The value is composed primarily from the sum of possible wins from every bet and further increased by the current maximum
   * Jackpot payout value for every bet playing for Jackpot (capped at 5 since Jackpots are very rare).
   *
   * Note re lock multiplier: the value should result in the locked amount conforming to the logic of computeJackpotAmount in Dice9.sol.
   * This would mean it needs to equal product JACKPOT_FEE and JACK_MODULO and maximum winning per paytable (4) divided
   * by the fixed point base of the jackpot multiplier (8).
   *
   * @param maxJackpotPayment maximum jackpot win amount according to the paytable.
   * @param jackpotMultiplierBase the denominator of the jackpotMultiplier value.
   *
   * @return the total number of funds required to cover the most extreme resolution of pending bets (everything wins everything).
   */
  function totalLockedInBets(State memory self, uint maxJackpotPayment, uint jackpotMultiplierBase) internal pure returns (uint) {
    // cap the amount of jackpot locks as those are rare and locks are too conservative as a result
    uint jackpotLocks = Math.min(self.jackpotBetCount, JACKPOT_LOCK_COUNT_CAP);
    uint jackpotLockedAmount = jackpotLocks * self.jackpotMultiplier * maxJackpotPayment / jackpotMultiplierBase;

    // compute total locked amount (regular bet winnings + jackpot winnings)
    return self.lockedInBets + jackpotLockedAmount;
  }
}