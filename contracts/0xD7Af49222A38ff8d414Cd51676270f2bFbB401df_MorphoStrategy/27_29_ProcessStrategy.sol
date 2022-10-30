// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./BaseStrategy.sol";

import "../libraries/Max/128Bit.sol";
import "../libraries/Math.sol";

struct ProcessInfo {
    uint128 totalWithdrawReceived;
    uint128 userDepositReceived;
}

/**
 * @notice Process strategy logic
 */
abstract contract ProcessStrategy is BaseStrategy {
    using Max128Bit for uint128;

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    /**
     * @notice Process the strategy pending deposits, withdrawals, and collected strategy rewards
     * @dev
     * Deposit amount amd withdrawal shares are matched between eachother, effecively only one of
     * those 2 is called. Shares are converted to the dollar value, based on the current strategy
     * total balance. This ensures the minimum amount of assets are moved around to lower the price
     * drift and total fees paid to the protocols the strategy is interacting with (if there are any)
     *
     * @param slippages Strategy slippage values verifying the validity of the strategy state
     * @param reallocateSharesToWithdraw Reallocation shares to withdraw (non-zero only if reallocation DHW is in progress, otherwise 0)
     */
    function _process(uint256[] memory slippages, uint128 reallocateSharesToWithdraw) internal override virtual {
        // PREPARE
        Strategy storage strategy = strategies[self];
        uint24 processingIndex = _getProcessingIndex();
        Batch storage batch = strategy.batches[processingIndex];
        uint128 strategyTotalShares = strategy.totalShares;
        uint128 pendingSharesToWithdraw = strategy.pendingUser.sharesToWithdraw.get();
        uint128 userDeposit = strategy.pendingUser.deposit.get();

        // CALCULATE THE ACTION

        // if withdrawing for reallocating, add shares to total withdraw shares
        if (reallocateSharesToWithdraw > 0) {
            pendingSharesToWithdraw += reallocateSharesToWithdraw;
        }

        // total deposit received from users + compound reward (if there are any)
        uint128 totalPendingDeposit = userDeposit;
        
        // add compound reward (pendingDepositReward) to deposit
        uint128 withdrawalReward = 0;
        if (strategy.pendingDepositReward > 0) {
            uint128 pendingDepositReward = strategy.pendingDepositReward;

            totalPendingDeposit += pendingDepositReward;

            // calculate compound reward (withdrawalReward) for users withdrawing in this batch
            if (pendingSharesToWithdraw > 0 && strategyTotalShares > 0) {
                withdrawalReward = Math.getProportion128(pendingSharesToWithdraw, pendingDepositReward, strategyTotalShares);

                // substract withdrawal reward from total deposit
                totalPendingDeposit -= withdrawalReward;
            }

            // Reset pendingDepositReward
            strategy.pendingDepositReward = 0;
        }

        // if there is no pending deposit or withdrawals, return
        if (totalPendingDeposit == 0 && pendingSharesToWithdraw == 0) {
            return;
        }

        uint128 pendingWithdrawalAmount = 0;
        if (pendingSharesToWithdraw > 0) {
            pendingWithdrawalAmount = 
                Math.getProportion128(getStrategyBalance(), pendingSharesToWithdraw, strategyTotalShares);
        }

        // ACTION: DEPOSIT OR WITHDRAW
        ProcessInfo memory processInfo;
        if (totalPendingDeposit > pendingWithdrawalAmount) { // DEPOSIT
            // uint128 amount = totalPendingDeposit - pendingWithdrawalAmount;
            uint128 depositReceived = _deposit(totalPendingDeposit - pendingWithdrawalAmount, slippages);

            processInfo.totalWithdrawReceived = pendingWithdrawalAmount + withdrawalReward;

            // pendingWithdrawalAmount is optimized deposit: totalPendingDeposit - amount;
            uint128 totalDepositReceived = depositReceived + pendingWithdrawalAmount;
            
            // calculate user deposit received, excluding compound rewards
            processInfo.userDepositReceived =  Math.getProportion128(totalDepositReceived, userDeposit, totalPendingDeposit);
        } else if (totalPendingDeposit < pendingWithdrawalAmount) { // WITHDRAW
            // uint128 amount = pendingWithdrawalAmount - totalPendingDeposit;

            uint128 withdrawReceived = _withdraw(
                // calculate back the shares from actual withdraw amount
                // NOTE: we can do unchecked calculation and casting as
                //       the multiplier is always smaller than the divisor
                Math.getProportion128Unchecked(
                    (pendingWithdrawalAmount - totalPendingDeposit),
                    pendingSharesToWithdraw,
                    pendingWithdrawalAmount
                ),
                slippages
            );

            // optimized withdraw is total pending deposit: pendingWithdrawalAmount - amount = totalPendingDeposit;
            processInfo.totalWithdrawReceived = withdrawReceived + totalPendingDeposit + withdrawalReward;
            processInfo.userDepositReceived = userDeposit;
        } else {
            processInfo.totalWithdrawReceived = pendingWithdrawalAmount + withdrawalReward;
            processInfo.userDepositReceived = userDeposit;
        }
        
        // UPDATE STORAGE AFTER
        {
            uint128 stratTotalUnderlying = getStrategyBalance();

            // Update withdraw batch
            if (pendingSharesToWithdraw > 0) {
                batch.withdrawnReceived = processInfo.totalWithdrawReceived;
                batch.withdrawnShares = pendingSharesToWithdraw;
                
                strategyTotalShares -= pendingSharesToWithdraw;

                // update reallocation batch
                if (reallocateSharesToWithdraw > 0) {
                    BatchReallocation storage reallocationBatch = strategy.reallocationBatches[processingIndex];

                    uint128 withdrawnReallocationReceived =
                        Math.getProportion128(processInfo.totalWithdrawReceived, reallocateSharesToWithdraw, pendingSharesToWithdraw);
                    reallocationBatch.withdrawnReallocationReceived = withdrawnReallocationReceived;

                    // substract reallocation values from user values
                    batch.withdrawnReceived -= withdrawnReallocationReceived;
                    batch.withdrawnShares -= reallocateSharesToWithdraw;
                }
            }

            // Update deposit batch
            if (userDeposit > 0) {
                uint128 newShares;
                (newShares, strategyTotalShares) = _getNewSharesAfterWithdraw(strategyTotalShares, stratTotalUnderlying, processInfo.userDepositReceived);

                batch.deposited = userDeposit;
                batch.depositedReceived = processInfo.userDepositReceived;
                batch.depositedSharesReceived = newShares;
            }

            // Update shares
            if (strategyTotalShares != strategy.totalShares) {
                strategy.totalShares = strategyTotalShares;
            }

            // Set underlying at index
            strategy.totalUnderlying[processingIndex].amount = stratTotalUnderlying;
            strategy.totalUnderlying[processingIndex].totalShares = strategyTotalShares;
        }
    }

    /**
     * @notice Process deposit
     * @param slippages Slippages array
     */
    function _processDeposit(uint256[] memory slippages) internal override virtual {
        Strategy storage strategy = strategies[self];
        
        uint128 depositOptimizedAmount = strategy.pendingReallocateOptimizedDeposit;
        uint128 depositAverageAmount = strategy.pendingReallocateAverageDeposit;
        uint128 optimizedSharesWithdrawn = strategy.optimizedSharesWithdrawn;
        uint128 depositAmount = strategy.pendingReallocateDeposit;

        // if a strategy is not part of reallocation return
        if (
            depositOptimizedAmount == 0 &&
            optimizedSharesWithdrawn == 0 &&
            depositAverageAmount == 0 &&
            depositAmount == 0
        ) {
            return;
        }

        uint24 processingIndex = _getProcessingIndex();
        BatchReallocation storage reallocationBatch = strategy.reallocationBatches[processingIndex];
        
        uint128 strategyTotalShares = strategy.totalShares;
        
        // add shares from optimized deposit
        if (depositOptimizedAmount > 0) {
            uint128 stratTotalUnderlying = getStrategyBalance();
            uint128 newShares;
            (newShares, strategyTotalShares) = _getNewShares(strategyTotalShares, stratTotalUnderlying, depositOptimizedAmount);

            // update reallocation batch deposit shares
            reallocationBatch.depositedReallocationSharesReceived = newShares;

            strategy.totalUnderlying[processingIndex].amount = stratTotalUnderlying;

            // reset
            strategy.pendingReallocateOptimizedDeposit = 0;
        }

        if (depositAverageAmount > 0) {
            reallocationBatch.depositedReallocation += depositAverageAmount;
            strategy.pendingReallocateAverageDeposit = 0;
        }

        // remove optimized withdraw shares
        if (optimizedSharesWithdrawn > 0) {
            strategyTotalShares -= optimizedSharesWithdrawn;

            // reset
            strategy.optimizedSharesWithdrawn = 0;
        }

        // add shares from actual deposit
        if (depositAmount > 0) {
            // deposit
            uint128 depositReceived = _deposit(depositAmount, slippages);

            // NOTE: might return it from _deposit (only certain strategies need it)
            uint128 stratTotalUnderlying = getStrategyBalance();

            if (depositReceived > 0) {
                uint128 newShares;
                (newShares, strategyTotalShares) = _getNewSharesAfterWithdraw(strategyTotalShares, stratTotalUnderlying, depositReceived);

                // update reallocation batch deposit shares
                reallocationBatch.depositedReallocationSharesReceived += newShares;
            }

            strategy.totalUnderlying[processingIndex].amount = stratTotalUnderlying;

            // reset
            strategy.pendingReallocateDeposit = 0;
        }

        // update share storage
        strategy.totalUnderlying[processingIndex].totalShares = strategyTotalShares;
        strategy.totalShares = strategyTotalShares;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice get the value of the strategy shares in the underlying tokens
     * @param shares Number of shares
     * @return amount Underling amount representing the `share` value of the strategy
     */
    function _getSharesToAmount(uint256 shares) internal virtual returns(uint128 amount) {
        amount = Math.getProportion128( getStrategyBalance(), shares, strategies[self].totalShares );
    }

    /**
     * @notice get slippage amount, and action type (withdraw/deposit).
     * @dev
     * Most significant bit represents an action, 0 for a withdrawal and 1 for deposit.
     *
     * This ensures the slippage will be used for the action intended by the do-hard-worker,
     * otherwise the transavtion will revert.
     *
     * @param slippageAction number containing the slippage action and the actual slippage amount
     * @return isDeposit Flag showing if the slippage is for the deposit action
     * @return slippage the slippage value cleaned of the most significant bit
     */
    function _getSlippageAction(uint256 slippageAction) internal pure returns (bool isDeposit, uint256 slippage) {
        // remove most significant bit
        slippage = (slippageAction << 1) >> 1;

        // if values are not the same (the removed bit was 1) set action to deposit
        if (slippageAction != slippage) {
            isDeposit = true;
        }
    }

    /* ========== VIRTUAL FUNCTIONS ========== */

    function _deposit(uint128 amount, uint256[] memory slippages) internal virtual returns(uint128 depositReceived);
    function _withdraw(uint128 shares, uint256[] memory slippages) internal virtual returns(uint128 withdrawReceived);
}