// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';

import { Bucket, Lender } from '../../interfaces/pool/commons/IPoolState.sol';

import { Maths } from './Maths.sol';

/**
    @title  Buckets library
    @notice Internal library containing common logic for buckets management.
 */
library Buckets {

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolError` for descriptions
    error BucketBankruptcyBlock();

    /***********************************/
    /*** Bucket Management Functions ***/
    /***********************************/

    /**
     *  @notice Add collateral to a bucket and updates `LP` for bucket and lender with the amount coresponding to collateral amount added.
     *  @dev    Increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev    - `addLenderLP`:
     *  @dev    increment `lender.lps` accumulator and `lender.depositTime` state
     *  @param  lender_                Address of the lender.
     *  @param  deposit_               Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  collateralAmountToAdd_ Additional collateral amount to add to bucket.
     *  @param  bucketPrice_           Bucket price.
     *  @return addedLP_               Amount of bucket `LP` for the collateral amount added.
     */
    function addCollateral(
        Bucket storage bucket_,
        address lender_,
        uint256 deposit_,
        uint256 collateralAmountToAdd_,
        uint256 bucketPrice_
    ) internal returns (uint256 addedLP_) {
        // cannot deposit in the same block when bucket becomes insolvent
        uint256 bankruptcyTime = bucket_.bankruptcyTime;
        if (bankruptcyTime == block.timestamp) revert BucketBankruptcyBlock();

        // calculate amount of LP to be added for the amount of collateral added to bucket
        addedLP_ = collateralToLP(
            bucket_.collateral,
            bucket_.lps,
            deposit_,
            collateralAmountToAdd_,
            bucketPrice_,
            Math.Rounding.Down
        );
        // update bucket LP balance and collateral

        // update bucket collateral
        bucket_.collateral += collateralAmountToAdd_;
        // update bucket and lender LP balance and deposit timestamp
        bucket_.lps += addedLP_;

        addLenderLP(bucket_, bankruptcyTime, lender_, addedLP_);
    }

    /**
     *  @notice Add amount of `LP` for a given lender in a given bucket.
     *  @dev    Increments lender lps accumulator and updates the deposit time.
     *  @param  bucket_         Bucket to record lender `LP`.
     *  @param  bankruptcyTime_ Time when bucket become insolvent.
     *  @param  lender_         Lender address to add `LP` for in the given bucket.
     *  @param  lpAmount_       Amount of `LP` to be recorded for the given lender.
     */
    function addLenderLP(
        Bucket storage bucket_,
        uint256 bankruptcyTime_,
        address lender_,
        uint256 lpAmount_
    ) internal {
        if (lpAmount_ != 0) {
            Lender storage lender = bucket_.lenders[lender_];

            if (bankruptcyTime_ >= lender.depositTime) lender.lps = lpAmount_;
            else lender.lps += lpAmount_;

            lender.depositTime = block.timestamp;
        }
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    /****************************/
    /*** Assets to LP helpers ***/
    /****************************/

    /**
     *  @notice Returns the amount of bucket `LP` calculated for the given amount of collateral.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  collateral_       The amount of collateral to calculate bucket LP for.
     *  @param  bucketPrice_      Bucket's price.
     *  @param  rounding_         The direction of rounding when calculating LP (down when adding, up when removing collateral from pool).
     *  @return Amount of `LP` calculated for the amount of collateral.
     */
    function collateralToLP(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 collateral_,
        uint256 bucketPrice_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        // case when there's no deposit nor collateral in bucket
        if (deposit_ == 0 && bucketCollateral_ == 0) return Maths.wmul(collateral_, bucketPrice_);

        // case when there's deposit or collateral in bucket but no LP to cover
        if (bucketLP_ == 0) return Maths.wmul(collateral_, bucketPrice_);

        // case when there's deposit or collateral and bucket has LP balance
        return Math.mulDiv(
            bucketLP_,
            collateral_ * bucketPrice_,
            deposit_ * Maths.WAD + bucketCollateral_ * bucketPrice_,
            rounding_
        );
    }

    /**
     *  @notice Returns the amount of `LP` calculated for the given amount of quote tokens.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  quoteTokens_      The amount of quote tokens to calculate `LP` amount for.
     *  @param  bucketPrice_      Bucket's price.
     *  @param  rounding_         The direction of rounding when calculating LP (down when adding, up when removing quote tokens from pool).
     *  @return The amount of `LP` coresponding to the given quote tokens in current bucket.
     */
    function quoteTokensToLP(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 quoteTokens_,
        uint256 bucketPrice_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        // case when there's no deposit nor collateral in bucket
        if (deposit_ == 0 && bucketCollateral_ == 0) return quoteTokens_;

        // case when there's deposit or collateral in bucket but no LP to cover
        if (bucketLP_ == 0) return quoteTokens_;

        // case when there's deposit or collateral and bucket has LP balance
        return Math.mulDiv(
            bucketLP_,
            quoteTokens_ * Maths.WAD,
            deposit_ * Maths.WAD + bucketCollateral_ * bucketPrice_,
            rounding_
        );
    }

    /****************************/
    /*** LP to Assets helpers ***/
    /****************************/

    /**
     *  @notice Returns the amount of collateral calculated for the given amount of lp
     *  @dev    The value returned is not capped at collateral amount available in bucket.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  lp_               The amount of LP to calculate collateral amount for.
     *  @param  bucketPrice_      Bucket's price.
     *  @return The amount of collateral coresponding to the given `LP` in current bucket.
     */
    function lpToCollateral(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 lp_,
        uint256 bucketPrice_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        // case when there's no deposit nor collateral in bucket
        if (deposit_ == 0 && bucketCollateral_ == 0) return Maths.wdiv(lp_, bucketPrice_);

        // case when there's deposit or collateral in bucket but no LP to cover
        if (bucketLP_ == 0) return Maths.wdiv(lp_, bucketPrice_);

        // case when there's deposit or collateral and bucket has LP balance
        return Math.mulDiv(
            deposit_ * Maths.WAD + bucketCollateral_ * bucketPrice_,
            lp_,
            bucketLP_ * bucketPrice_,
            rounding_
        );
    }

    /**
     *  @notice Returns the amount of quote token (in value) calculated for the given amount of `LP`.
     *  @dev    The value returned is not capped at available bucket deposit.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  lp_               The amount of LP to calculate quote tokens amount for.
     *  @param  bucketPrice_      Bucket's price.
     *  @return The amount coresponding to the given quote tokens in current bucket.
     */
    function lpToQuoteTokens(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 lp_,
        uint256 bucketPrice_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        // case when there's no deposit nor collateral in bucket
        if (deposit_ == 0 && bucketCollateral_ == 0) return lp_;

        // case when there's deposit or collateral in bucket but no LP to cover
        if (bucketLP_ == 0) return lp_;

        // case when there's deposit or collateral and bucket has LP balance
        return Math.mulDiv(
            deposit_ * Maths.WAD + bucketCollateral_ * bucketPrice_,
            lp_,
            bucketLP_ * Maths.WAD,
            rounding_
        );
    }

    /****************************/
    /*** Exchange Rate helper ***/
    /****************************/

    /**
     *  @notice Returns the exchange rate for a given bucket (conversion of 1 lp to quote token).
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  bucketDeposit_    The amount of quote tokens deposited in the given bucket.
     *  @param  bucketPrice_      Bucket's price.
     */
    function getExchangeRate(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 bucketDeposit_,
        uint256 bucketPrice_
    ) internal pure returns (uint256) {
        return lpToQuoteTokens(
            bucketCollateral_,
            bucketLP_,
            bucketDeposit_,
            Maths.WAD,
            bucketPrice_,
            Math.Rounding.Up
        );
    }
}