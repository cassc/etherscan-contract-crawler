// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAloeBlendDerivedState {
    /**
     * @notice Calculates the rebalance urgency. Caller's reward is proportional to this value. Target is 100000
     * @return urgency How badly the vault wants its `rebalance()` function to be called
     */
    function getRebalanceUrgency() external view returns (uint32 urgency);

    /**
     * @notice Estimate's the vault's liabilities to users -- in other words, how much would be paid out if all
     * holders redeemed their shares at once.
     * @dev Underestimates the true payout unless both silos and Uniswap positions have just been poked. Also
     * assumes that the maximum amount will accrue to the maintenance budget during the next `rebalance()`. If
     * it takes less than that for the budget to reach capacity, then the values reported here may increase after
     * calling `rebalance()`.
     * @return inventory0 The amount of token0 underlying all shares
     * @return inventory1 The amount of token1 underlying all shares
     */
    function getInventory() external view returns (uint256 inventory0, uint256 inventory1);
}