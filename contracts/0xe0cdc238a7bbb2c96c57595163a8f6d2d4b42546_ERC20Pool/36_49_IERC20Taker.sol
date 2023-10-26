// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IERC20Taker {
    /**
     *  @notice Called by `Pool.take` allowing a taker to externally swap collateral for quote token.
     *  @param  collateralAmount The denormalized amount of collateral being taken (`WAD` precision).
     *  @param  quoteAmountDue   Denormalized amount of quote token required to purchase `collateralAmount` at the 
     *                           current auction price (`WAD` precision).
     *  @param  data             Taker-provided calldata passed from taker's invocation to their callback.
     */
    function atomicSwapCallback(
        uint256        collateralAmount, 
        uint256        quoteAmountDue,
        bytes calldata data
    ) external;
}