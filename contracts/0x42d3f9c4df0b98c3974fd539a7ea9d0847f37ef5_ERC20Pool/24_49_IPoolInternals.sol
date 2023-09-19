// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Internal structs used by the pool / libraries
 */

/*****************************/
/*** Auction Param Structs ***/
/*****************************/

/// @dev Struct used to return result of `KickerAction.kick` action.
struct KickResult {
    uint256 amountToCoverBond;    // [WAD] amount of bond that needs to be covered
    uint256 t0PoolDebt;           // [WAD] t0 debt in pool after kick
    uint256 t0KickedDebt;         // [WAD] new t0 debt after kick
    uint256 debtPreAction;        // [WAD] The amount of borrower t0 debt before kick
    uint256 collateralPreAction;  // [WAD] The amount of borrower collateral before kick, same as the one after kick
    uint256 poolDebt;             // [WAD] current debt in pool after kick
    uint256 lup;                  // [WAD] current LUP in pool after kick
}

/// @dev Struct used to hold parameters for `SettlerAction.settlePoolDebt` action.
struct SettleParams {
    address borrower;    // borrower address to settle
    uint256 bucketDepth; // number of buckets to use when settle debt
    uint256 poolBalance; // current pool quote token balance
}

/// @dev Struct used to return result of `SettlerAction.settlePoolDebt` action.
struct SettleResult {
    uint256 debtPreAction;       // [WAD] The amount of borrower t0 debt before settle
    uint256 debtPostAction;      // [WAD] The amount of borrower t0 debt remaining after settle
    uint256 collateralPreAction; // [WAD] The amount of borrower collateral before settle
    uint256 collateralRemaining; // [WAD] The amount of borrower collateral left after settle
    uint256 collateralSettled;   // [WAD] The amount of borrower collateral settled
    uint256 t0DebtSettled;       // [WAD] The amount of t0 debt settled
}

/// @dev Struct used to return result of `TakerAction.take` and `TakerAction.bucketTake` actions.
struct TakeResult {
    uint256 collateralAmount;      // [WAD] amount of collateral taken
    uint256 compensatedCollateral; // [WAD] amount of borrower collateral that is compensated with LP
    uint256 quoteTokenAmount;      // [WAD] amount of quote tokens paid by taker for taken collateral, used in take action
    uint256 t0DebtPenalty;         // [WAD] t0 penalty applied on first take
    uint256 excessQuoteToken;      // [WAD] (NFT only) amount of quote tokens to be paid by taker to borrower for fractional collateral, used in take action
    uint256 remainingCollateral;   // [WAD] amount of borrower collateral remaining after take
    uint256 poolDebt;              // [WAD] current pool debt
    uint256 t0PoolDebt;            // [WAD] t0 pool debt
    uint256 newLup;                // [WAD] current lup
    uint256 t0DebtInAuctionChange; // [WAD] the amount of t0 debt recovered by take action
    bool    settledAuction;        // true if auction is settled by take action
    uint256 debtPreAction;         // [WAD] The amount of borrower t0 debt before take
    uint256 debtPostAction;        // [WAD] The amount of borrower t0 debt after take
    uint256 collateralPreAction;   // [WAD] The amount of borrower collateral before take
    uint256 collateralPostAction;  // [WAD] The amount of borrower collateral after take
}

/// @dev Struct used to hold parameters for `KickerAction.kickReserveAuction` action.
struct KickReserveAuctionParams {
    uint256 poolSize;    // [WAD] total deposits in pool (with accrued debt)
    uint256 t0PoolDebt;  // [WAD] current t0 pool debt
    uint256 poolBalance; // [WAD] pool quote token balance
    uint256 inflator;    // [WAD] pool current inflator
}

/******************************************/
/*** Liquidity Management Param Structs ***/
/******************************************/

/// @dev Struct used to hold parameters for `LenderAction.addQuoteToken` action.
struct AddQuoteParams {
    uint256 amount;           // [WAD] amount to be added
    uint256 index;            // the index in which to deposit
    bool    revertIfBelowLup; // revert tx if index in which to deposit is below LUP
}

/// @dev Struct used to hold parameters for `LenderAction.moveQuoteToken` action.
struct MoveQuoteParams {
    uint256 fromIndex;        // the deposit index from where amount is moved
    uint256 maxAmountToMove;  // [WAD] max amount to move between deposits
    uint256 toIndex;          // the deposit index where amount is moved to
    uint256 thresholdPrice;   // [WAD] max threshold price in pool
    bool    revertIfBelowLup; // revert tx if quote token is moved from above the LUP to below the LUP
}

/// @dev Struct used to hold parameters for `LenderAction.removeQuoteToken` action.
struct RemoveQuoteParams {
    uint256 index;           // the deposit index from where amount is removed
    uint256 maxAmount;       // [WAD] max amount to be removed
    uint256 thresholdPrice;  // [WAD] max threshold price in pool
}

/*************************************/
/*** Loan Management Param Structs ***/
/*************************************/

/// @dev Struct used to return result of `BorrowerActions.drawDebt` action.
struct DrawDebtResult {
    bool    inAuction;             // true if loan still in auction after pledge more collateral, false otherwise
    uint256 newLup;                // [WAD] new pool LUP after draw debt
    uint256 poolCollateral;        // [WAD] total amount of collateral in pool after pledge collateral
    uint256 poolDebt;              // [WAD] total accrued debt in pool after draw debt
    uint256 remainingCollateral;   // [WAD] amount of borrower collateral after draw debt (for NFT can be diminished if auction settled)
    bool    settledAuction;        // true if collateral pledged settles auction
    uint256 t0DebtInAuctionChange; // [WAD] change of t0 pool debt in auction after pledge collateral
    uint256 t0PoolDebt;            // [WAD] amount of t0 debt in pool after draw debt
    uint256 debtPreAction;         // [WAD] The amount of borrower t0 debt before draw debt
    uint256 debtPostAction;        // [WAD] The amount of borrower t0 debt after draw debt
    uint256 collateralPreAction;   // [WAD] The amount of borrower collateral before draw debt
    uint256 collateralPostAction;  // [WAD] The amount of borrower collateral after draw debt
}

/// @dev Struct used to return result of `BorrowerActions.repayDebt` action.
struct RepayDebtResult {
    bool    inAuction;             // true if loan still in auction after repay, false otherwise
    uint256 newLup;                // [WAD] new pool LUP after draw debt
    uint256 poolCollateral;        // [WAD] total amount of collateral in pool after pull collateral
    uint256 poolDebt;              // [WAD] total accrued debt in pool after repay debt
    uint256 remainingCollateral;   // [WAD] amount of borrower collateral after pull collateral
    bool    settledAuction;        // true if repay debt settles auction
    uint256 t0DebtInAuctionChange; // [WAD] change of t0 pool debt in auction after repay debt
    uint256 t0PoolDebt;            // [WAD] amount of t0 debt in pool after repay
    uint256 quoteTokenToRepay;     // [WAD] quote token amount to be transferred from sender to pool
    uint256 debtPreAction;         // [WAD] The amount of borrower t0 debt before repay debt
    uint256 debtPostAction;        // [WAD] The amount of borrower t0 debt after repay debt
    uint256 collateralPreAction;   // [WAD] The amount of borrower collateral before repay debt
    uint256 collateralPostAction;  // [WAD] The amount of borrower collateral after repay debt
}