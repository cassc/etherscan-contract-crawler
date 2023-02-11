// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

/**
 * @title LS1Types
 * @author MarginX
 *
 * @dev Structs used by the LiquidityStaking contract.
 */
library LS1Types {
  /**
   * @dev The parameters used to convert a timestamp to an epoch number.
   */
  struct EpochParameters {
    uint128 interval;
    uint128 offset;
  }

  /**
   * @dev The parameters representing a shortfall event.
   *
   * @param  index  Fraction of inactive funds converted into debt, scaled by SHORTFALL_INDEX_BASE.
   * @param  epoch  The epoch in which the shortfall occurred.
   */
  struct Shortfall {
    uint16 epoch; // Note: Supports at least 1000 years given min epoch length of 6 days.
    uint224 index; // Note: Save on contract bytecode size by reusing uint224 instead of uint240.
  }

  /**
   * @dev A balance, possibly with a change scheduled for the next epoch.
   *  Also includes cached index information for inactive balances.
   *
   * @param  currentEpoch         The epoch in which the balance was last updated.
   * @param  currentEpochBalance  The balance at epoch `currentEpoch`.
   * @param  nextEpochBalance     The balance at epoch `currentEpoch + 1`.
   * @param  shortfallCounter     Incrementing counter of the next shortfall index to be applied.
   */
  struct StoredBalance {
    uint16 currentEpoch; // Supports at least 1000 years given min epoch length of 6 days.
    uint128 currentEpochBalance;
    uint128 nextEpochBalance;
    uint16 shortfallCounter; // Only for staker inactive balances. At most one shortfall per epoch.
  }

  /**
   * @dev A borrower allocation, possibly with a change scheduled for the next epoch.
   */
  struct StoredAllocation {
    uint16 currentEpoch; // Note: Supports at least 1000 years given min epoch length of 6 days.
    uint128 currentEpochAllocation;
    uint128 nextEpochAllocation;
  }
}