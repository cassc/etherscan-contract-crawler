// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';

import {
    AddQuoteParams,
    MoveQuoteParams,
    RemoveQuoteParams
}                     from '../../interfaces/pool/commons/IPoolInternals.sol';
import {
    Bucket,
    DepositsState,
    Lender,
    PoolState
}                     from '../../interfaces/pool/commons/IPoolState.sol';

import { _depositFeeRate, _priceAt, MAX_FENWICK_INDEX } from '../helpers/PoolHelper.sol';

import { Deposits } from '../internal/Deposits.sol';
import { Buckets }  from '../internal/Buckets.sol';
import { Maths }    from '../internal/Maths.sol';

/**
    @title  LenderActions library
    @notice External library containing logic for lender actors:
            - `Lenders`: add, remove and move quote tokens;
            - `Traders`: add, remove and move quote tokens; add and remove collateral
 */
library LenderActions {

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `moveQuoteToken` function local vars.
    struct MoveQuoteLocalVars {
        uint256 fromBucketPrice;            // [WAD] Price of the bucket to move amount from.
        uint256 fromBucketCollateral;       // [WAD] Total amount of collateral in from bucket.
        uint256 fromBucketLP;               // [WAD] Total amount of LP in from bucket.
        uint256 fromBucketLenderLP;         // [WAD] Amount of LP owned by lender in from bucket.
        uint256 fromBucketDepositTime;      // Time of lender deposit in the bucket to move amount from.
        uint256 fromBucketRemainingLP;      // Amount of LP remaining in from bucket after move.
        uint256 fromBucketRemainingDeposit; // Amount of scaled deposit remaining in from bucket after move.
        uint256 toBucketPrice;              // [WAD] Price of the bucket to move amount to.
        uint256 toBucketBankruptcyTime;     // Time the bucket to move amount to was marked as insolvent.
        uint256 toBucketDepositTime;        // Time of lender deposit in the bucket to move amount to.
        uint256 toBucketUnscaledDeposit;    // Amount of unscaled deposit in to bucket.
        uint256 toBucketDeposit;            // Amount of scaled deposit in to bucket.
        uint256 toBucketScale;              // Scale deposit of to bucket.
        uint256 ptp;                        // [WAD] Pool Threshold Price.
        uint256 htp;                        // [WAD] Highest Threshold Price.
    }

    /// @dev Struct used for `removeQuoteToken` function local vars.
    struct RemoveDepositParams {
        uint256 depositConstraint; // [WAD] Constraint on deposit in quote token.
        uint256 lpConstraint;      // [WAD] Constraint in LPB terms.
        uint256 bucketLP;          // [WAD] Total LPB in the bucket.
        uint256 bucketCollateral;  // [WAD] Claimable collateral in the bucket.
        uint256 price;             // [WAD] Price of bucket.
        uint256 index;             // Bucket index.
        uint256 dustLimit;         // Minimum amount of deposit which may reside in a bucket.
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event AddQuoteToken(address indexed lender, uint256 indexed index, uint256 amount, uint256 lpAwarded, uint256 lup);
    event BucketBankruptcy(uint256 indexed index, uint256 lpForfeited);
    event MoveQuoteToken(address indexed lender, uint256 indexed from, uint256 indexed to, uint256 amount, uint256 lpRedeemedFrom, uint256 lpAwardedTo, uint256 lup);
    event RemoveQuoteToken(address indexed lender, uint256 indexed index, uint256 amount, uint256 lpRedeemed, uint256 lup);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error BucketBankruptcyBlock();
    error CannotMergeToHigherPrice();
    error DustAmountNotExceeded();
    error InvalidIndex();
    error InvalidAmount();
    error LUPBelowHTP();
    error NoClaim();
    error InsufficientLP();
    error InsufficientLiquidity();
    error InsufficientCollateral();
    error MoveToSameIndex();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IERC20PoolLenderActions` and `IERC721PoolLenderActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `Buckets.addCollateral`:
     *  @dev      increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev      `addLenderLP`: increment `lender.lps` accumulator and `lender.depositTime `state
     *  @dev    === Reverts on ===
     *  @dev    invalid bucket index `InvalidIndex()`
     *  @dev    no LP awarded in bucket `InsufficientLP()`
     */
    function addCollateral(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        uint256 collateralAmountToAdd_,
        uint256 index_
    ) external returns (uint256 bucketLP_) {
        // revert if no amount to be added
        if (collateralAmountToAdd_ == 0) revert InvalidAmount();
        // revert if adding at invalid index
        if (index_ == 0 || index_ > MAX_FENWICK_INDEX) revert InvalidIndex();

        uint256 bucketDeposit = Deposits.valueAt(deposits_, index_);
        uint256 bucketPrice   = _priceAt(index_);

        bucketLP_ = Buckets.addCollateral(
            buckets_[index_],
            msg.sender,
            bucketDeposit,
            collateralAmountToAdd_,
            bucketPrice
        );

        // revert if (due to rounding) the awarded LP is 0
        if (bucketLP_ == 0) revert InsufficientLP();
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `Deposits.unscaledAdd` (add new amount in `Fenwick` tree): update `values` array state 
     *  @dev    - increment `bucket.lps` accumulator
     *  @dev    - increment `lender.lps` accumulator and `lender.depositTime` state
     *  @dev    === Reverts on ===
     *  @dev    invalid bucket index `InvalidIndex()`
     *  @dev    same block when bucket becomes insolvent `BucketBankruptcyBlock()`
     *  @dev    no LP awarded in bucket `InsufficientLP()`
     *  @dev    calculated unscaled amount to add is 0 `InvalidAmount()`
     *  @dev    === Emit events ===
     *  @dev    - `AddQuoteToken`
     */
    function addQuoteToken(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        PoolState calldata poolState_,
        AddQuoteParams calldata params_
    ) external returns (uint256 bucketLP_, uint256 lup_) {
        // revert if no amount to be added
        if (params_.amount == 0) revert InvalidAmount();
        // revert if adding to an invalid index
        if (params_.index == 0 || params_.index > MAX_FENWICK_INDEX) revert InvalidIndex();

        Bucket storage bucket = buckets_[params_.index];

        uint256 bankruptcyTime = bucket.bankruptcyTime;

        // cannot deposit in the same block when bucket becomes insolvent
        if (bankruptcyTime == block.timestamp) revert BucketBankruptcyBlock();

        uint256 unscaledBucketDeposit = Deposits.unscaledValueAt(deposits_, params_.index);
        uint256 bucketScale           = Deposits.scale(deposits_, params_.index);
        uint256 bucketDeposit         = Maths.wmul(bucketScale, unscaledBucketDeposit);
        uint256 bucketPrice           = _priceAt(params_.index);
        uint256 addedAmount           = params_.amount;

        // charge unutilized deposit fee where appropriate
        uint256 lupIndex = Deposits.findIndexOfSum(deposits_, poolState_.debt);
        bool depositBelowLup = lupIndex != 0 && params_.index > lupIndex;
        if (depositBelowLup) {
            addedAmount = Maths.wmul(addedAmount, Maths.WAD - _depositFeeRate(poolState_.rate));
        }

        bucketLP_ = Buckets.quoteTokensToLP(
            bucket.collateral,
            bucket.lps,
            bucketDeposit,
            addedAmount,
            bucketPrice,
            Math.Rounding.Down
        );

        // revert if (due to rounding) the awarded LP is 0
        if (bucketLP_ == 0) revert InsufficientLP();

        uint256 unscaledAmount = Maths.wdiv(addedAmount, bucketScale);
        // revert if unscaled amount is 0
        if (unscaledAmount == 0) revert InvalidAmount();

        Deposits.unscaledAdd(deposits_, params_.index, unscaledAmount);

        // update lender LP
        Buckets.addLenderLP(bucket, bankruptcyTime, msg.sender, bucketLP_);

        // update bucket LP
        bucket.lps += bucketLP_;

        // only need to recalculate LUP if the deposit was above it
        if (!depositBelowLup) {
            lupIndex = Deposits.findIndexOfSum(deposits_, poolState_.debt);
        }
        lup_ = _priceAt(lupIndex);

        emit AddQuoteToken(
            msg.sender,
            params_.index,
            addedAmount,
            bucketLP_,
            lup_
        );
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `_removeMaxDeposit`:
     *  @dev      `Deposits.unscaledRemove` (remove amount in `Fenwick` tree, from index): update `values` array state
     *  @dev    - `Deposits.unscaledAdd` (add amount in `Fenwick` tree, to index): update `values` array state
     *  @dev    - decrement `lender.lps` accumulator for from bucket
     *  @dev    - increment `lender.lps` accumulator and `lender.depositTime` state for to bucket
     *  @dev    - decrement `bucket.lps` accumulator for from bucket
     *  @dev    - increment `bucket.lps` accumulator for to bucket
     *  @dev    === Reverts on ===
     *  @dev    same index `MoveToSameIndex()`
     *  @dev    dust amount `DustAmountNotExceeded()`
     *  @dev    invalid index `InvalidIndex()`
     *  @dev    no LP awarded in to bucket `InsufficientLP()`
     *  @dev    === Emit events ===
     *  @dev    - `BucketBankruptcy`
     *  @dev    - `MoveQuoteToken`
     */
    function moveQuoteToken(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        PoolState calldata poolState_,
        MoveQuoteParams calldata params_
    ) external returns (uint256 fromBucketRedeemedLP_, uint256 toBucketLP_, uint256 movedAmount_, uint256 lup_) {
        if (params_.maxAmountToMove == 0)
            revert InvalidAmount();
        if (params_.fromIndex == params_.toIndex)
            revert MoveToSameIndex();
        if (params_.maxAmountToMove != 0 && params_.maxAmountToMove < poolState_.quoteTokenScale)
            revert DustAmountNotExceeded();
        if (params_.toIndex == 0 || params_.toIndex > MAX_FENWICK_INDEX) 
            revert InvalidIndex();

        Bucket storage toBucket = buckets_[params_.toIndex];

        MoveQuoteLocalVars memory vars;
        vars.toBucketBankruptcyTime = toBucket.bankruptcyTime;

        // cannot move in the same block when target bucket becomes insolvent
        if (vars.toBucketBankruptcyTime == block.timestamp) revert BucketBankruptcyBlock();

        Bucket storage fromBucket       = buckets_[params_.fromIndex];
        Lender storage fromBucketLender = fromBucket.lenders[msg.sender];

        vars.fromBucketPrice       = _priceAt(params_.fromIndex);
        vars.fromBucketCollateral  = fromBucket.collateral;
        vars.fromBucketLP          = fromBucket.lps;
        vars.fromBucketDepositTime = fromBucketLender.depositTime;

        vars.toBucketPrice         = _priceAt(params_.toIndex);

        if (fromBucket.bankruptcyTime < vars.fromBucketDepositTime) vars.fromBucketLenderLP = fromBucketLender.lps;

        (movedAmount_, fromBucketRedeemedLP_, vars.fromBucketRemainingDeposit) = _removeMaxDeposit(
            deposits_,
            RemoveDepositParams({
                depositConstraint: params_.maxAmountToMove,
                lpConstraint:      vars.fromBucketLenderLP,
                bucketLP:          vars.fromBucketLP,
                bucketCollateral:  vars.fromBucketCollateral,
                price:             vars.fromBucketPrice,
                index:             params_.fromIndex,
                dustLimit:         poolState_.quoteTokenScale
            })
        );

        lup_ = Deposits.getLup(deposits_, poolState_.debt);
        // apply unutilized deposit fee if quote token is moved from above the LUP to below the LUP
        if (vars.fromBucketPrice >= lup_ && vars.toBucketPrice < lup_) {
            movedAmount_ = Maths.wmul(movedAmount_, Maths.WAD - _depositFeeRate(poolState_.rate));
        }

        vars.toBucketUnscaledDeposit = Deposits.unscaledValueAt(deposits_, params_.toIndex);
        vars.toBucketScale           = Deposits.scale(deposits_, params_.toIndex);
        vars.toBucketDeposit         = Maths.wmul(vars.toBucketUnscaledDeposit, vars.toBucketScale);

        toBucketLP_ = Buckets.quoteTokensToLP(
            toBucket.collateral,
            toBucket.lps,
            vars.toBucketDeposit,
            movedAmount_,
            vars.toBucketPrice,
            Math.Rounding.Down
        );

        // revert if (due to rounding) the awarded LP in to bucket is 0
        if (toBucketLP_ == 0) revert InsufficientLP();

        Deposits.unscaledAdd(deposits_, params_.toIndex, Maths.wdiv(movedAmount_, vars.toBucketScale));

        vars.htp = Maths.wmul(params_.thresholdPrice, poolState_.inflator);

        // check loan book's htp against new lup, revert if move drives LUP below HTP
        if (params_.fromIndex < params_.toIndex && vars.htp > lup_) revert LUPBelowHTP();

        // update lender and bucket LP balance in from bucket
        vars.fromBucketRemainingLP = vars.fromBucketLP - fromBucketRedeemedLP_;

        // check if from bucket healthy after move quote tokens - set bankruptcy if collateral and deposit are 0 but there's still LP
        if (vars.fromBucketCollateral == 0 && vars.fromBucketRemainingDeposit == 0 && vars.fromBucketRemainingLP != 0) {
            fromBucket.lps            = 0;
            fromBucket.bankruptcyTime = block.timestamp;

            emit BucketBankruptcy(
                params_.fromIndex,
                vars.fromBucketRemainingLP
            );
        } else {
            // update lender and bucket LP balance
            fromBucketLender.lps -= fromBucketRedeemedLP_;

            fromBucket.lps = vars.fromBucketRemainingLP;
        }

        // update lender and bucket LP balance in target bucket
        Lender storage toBucketLender = toBucket.lenders[msg.sender];

        vars.toBucketDepositTime = toBucketLender.depositTime;
        if (vars.toBucketBankruptcyTime >= vars.toBucketDepositTime) {
            // bucket is bankrupt and deposit was done before bankruptcy time, reset lender lp amount
            toBucketLender.lps = toBucketLP_;

            // set deposit time of the lender's to bucket as bucket's last bankruptcy timestamp + 1 so deposit won't get invalidated
            vars.toBucketDepositTime = vars.toBucketBankruptcyTime + 1;
        } else {
            toBucketLender.lps += toBucketLP_;
        }

        // set deposit time to the greater of the lender's from bucket and the target bucket
        toBucketLender.depositTime = Maths.max(vars.fromBucketDepositTime, vars.toBucketDepositTime);

        // update bucket LP balance
        toBucket.lps += toBucketLP_;

        emit MoveQuoteToken(
            msg.sender,
            params_.fromIndex,
            params_.toIndex,
            movedAmount_,
            fromBucketRedeemedLP_,
            toBucketLP_,
            lup_
        );
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `_removeMaxDeposit`:
     *  @dev      `Deposits.unscaledRemove` (remove amount in `Fenwick` tree, from index): update `values` array state
     *  @dev    - decrement `lender.lps` accumulator
     *  @dev    - decrement `bucket.lps` accumulator
     *  @dev    === Reverts on ===
     *  @dev    no `LP` `NoClaim()`;
     *  @dev    `LUP` lower than `HTP` `LUPBelowHTP()`
     *  @dev    === Emit events ===
     *  @dev    - `RemoveQuoteToken`
     *  @dev    - `BucketBankruptcy`
     */
    function removeQuoteToken(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        PoolState calldata poolState_,
        RemoveQuoteParams calldata params_
    ) external returns (uint256 removedAmount_, uint256 redeemedLP_, uint256 lup_) {
        // revert if no amount to be removed
        if (params_.maxAmount == 0) revert InvalidAmount();

        Bucket storage bucket = buckets_[params_.index];
        Lender storage lender = bucket.lenders[msg.sender];

        uint256 depositTime = lender.depositTime;

        RemoveDepositParams memory removeParams;

        if (bucket.bankruptcyTime < depositTime) removeParams.lpConstraint = lender.lps;

        // revert if no LP to claim
        if (removeParams.lpConstraint == 0) revert NoClaim();

        removeParams.depositConstraint = params_.maxAmount;
        removeParams.price             = _priceAt(params_.index);
        removeParams.bucketLP          = bucket.lps;
        removeParams.bucketCollateral  = bucket.collateral;
        removeParams.index             = params_.index;
        removeParams.dustLimit         = poolState_.quoteTokenScale;

        uint256 unscaledRemaining;

        (removedAmount_, redeemedLP_, unscaledRemaining) = _removeMaxDeposit(
            deposits_,
            removeParams
        );

        lup_ = Deposits.getLup(deposits_, poolState_.debt);

        uint256 htp = Maths.wmul(params_.thresholdPrice, poolState_.inflator);

        if (
            // check loan book's htp doesn't exceed new lup
            htp > lup_
            ||
            // ensure that pool debt < deposits after removal
            // this can happen if lup and htp are less than min bucket price and htp > lup (since LUP is capped at min bucket price)
            (poolState_.debt != 0 && poolState_.debt > Deposits.treeSum(deposits_))
        ) revert LUPBelowHTP();

        uint256 lpRemaining = removeParams.bucketLP - redeemedLP_;

        // check if bucket healthy after remove quote tokens - set bankruptcy if collateral and deposit are 0 but there's still LP
        if (removeParams.bucketCollateral == 0 && unscaledRemaining == 0 && lpRemaining != 0) {
            bucket.lps            = 0;
            bucket.bankruptcyTime = block.timestamp;

            emit BucketBankruptcy(
                params_.index,
                lpRemaining
            );
        } else {
            // update lender and bucket LP balances
            lender.lps -= redeemedLP_;

            bucket.lps = lpRemaining;
        }

        emit RemoveQuoteToken(
            msg.sender,
            params_.index,
            removedAmount_,
            redeemedLP_,
            lup_
        );
    }

    /**
     *  @notice See `IPoolLenderActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    decrement `lender.lps` accumulator
     *  @dev    decrement `bucket.collateral` and `bucket.lps` accumulator
     *  @dev    === Reverts on ===
     *  @dev    not enough collateral `InsufficientCollateral()`
     *  @dev    no `LP` redeemed `InsufficientLP()`
     *  @dev    === Emit events ===
     *  @dev    - `BucketBankruptcy`
     */
    function removeCollateral(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        uint256 amount_,
        uint256 index_
    ) external returns (uint256 lpAmount_) {
        // revert if no amount to be removed
        if (amount_ == 0) revert InvalidAmount();

        Bucket storage bucket = buckets_[index_];

        uint256 bucketCollateral = bucket.collateral;

        if (amount_ > bucketCollateral) revert InsufficientCollateral();

        uint256 bucketPrice   = _priceAt(index_);
        uint256 bucketLP      = bucket.lps;
        uint256 bucketDeposit = Deposits.valueAt(deposits_, index_);

        lpAmount_ = Buckets.collateralToLP(
            bucketCollateral,
            bucketLP,
            bucketDeposit,
            amount_,
            bucketPrice,
            Math.Rounding.Up
        );

        // revert if (due to rounding) required LP is 0
        if (lpAmount_ == 0) revert InsufficientLP();

        Lender storage lender = bucket.lenders[msg.sender];

        uint256 lenderLpBalance;
        if (bucket.bankruptcyTime < lender.depositTime) lenderLpBalance = lender.lps;
        if (lenderLpBalance == 0 || lpAmount_ > lenderLpBalance) revert InsufficientLP();

        // update bucket LP and collateral balance
        bucketLP -= lpAmount_;

        // If clearing out the bucket collateral, ensure it's zeroed out
        if (bucketLP == 0 && bucketDeposit == 0) {
            amount_ = bucketCollateral;
        }

        bucketCollateral  -= amount_;
        bucket.collateral = bucketCollateral;

        // check if bucket healthy after collateral remove - set bankruptcy if collateral and deposit are 0 but there's still LP
        if (bucketCollateral == 0 && bucketDeposit == 0 && bucketLP != 0) {
            bucket.lps            = 0;
            bucket.bankruptcyTime = block.timestamp;

            emit BucketBankruptcy(
                index_,
                bucketLP
            );
        } else {
            // update lender and bucket LP balances
            lender.lps -= lpAmount_;
            bucket.lps = bucketLP;
        }
    }

    /**
     *  @notice Removes max collateral amount from a given bucket index.
     *  @dev    === Write state ===
     *  @dev    - `_removeMaxCollateral`:
     *  @dev      decrement `lender.lps` accumulator
     *  @dev      decrement `bucket.collateral` and `bucket.lps` accumulator
     *  @dev    === Reverts on ===
     *  @dev    not enough collateral `InsufficientCollateral()`
     *  @dev    no claim `NoClaim()`
     *  @dev    leaves less than dust limit in bucket `DustAmountNotExceeded()`
     *  @return Amount of collateral that was removed.
     *  @return Amount of LP redeemed for removed collateral amount.
     */
    function removeMaxCollateral(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        uint256 dustLimit_,
        uint256 maxAmount_,
        uint256 index_
    ) external returns (uint256, uint256) {
        // revert if no amount to remove
        if (maxAmount_ == 0) revert InvalidAmount();

        return _removeMaxCollateral(
            buckets_,
            deposits_,
            dustLimit_,
            maxAmount_,
            index_
        );
    }

    /**
     *  @notice See `IERC721PoolLenderActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `Buckets.addCollateral`:
     *  @dev      increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev      increment `lender.lps` accumulator and `lender.depositTime` state
     *  @dev    === Reverts on ===
     *  @dev    invalid merge index `CannotMergeToHigherPrice()`
     *  @dev    no `LP` awarded in `toIndex_` bucket `InsufficientLP()`
     *  @dev    no collateral removed from bucket `InvalidAmount()`
     */
    function mergeOrRemoveCollateral(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        uint256[] calldata removalIndexes_,
        uint256 collateralAmount_,
        uint256 toIndex_
    ) external returns (uint256 collateralToMerge_, uint256 bucketLP_) {
        uint256 i;
        uint256 fromIndex;
        uint256 collateralRemoved;
        uint256 noOfBuckets = removalIndexes_.length;
        uint256 collateralRemaining = collateralAmount_;

        // Loop over buckets, exit if collateralAmount is reached or max noOfBuckets is reached
        while (collateralToMerge_ < collateralAmount_ && i < noOfBuckets) {
            fromIndex = removalIndexes_[i];

            if (fromIndex > toIndex_) revert CannotMergeToHigherPrice();

            (collateralRemoved, ) = _removeMaxCollateral(
                buckets_,
                deposits_,
                1,                   // dust limit is same as collateral scale
                collateralRemaining,
                fromIndex
            );

            // revert if calculated amount of collateral to remove is 0
            if (collateralRemoved == 0) revert InvalidAmount();

            collateralToMerge_ += collateralRemoved;

            collateralRemaining = collateralRemaining - collateralRemoved;

            unchecked { ++i; }
        }

        if (collateralToMerge_ != collateralAmount_) {
            // Merge totalled collateral to specified bucket, toIndex_
            uint256 toBucketDeposit = Deposits.valueAt(deposits_, toIndex_);
            uint256 toBucketPrice   = _priceAt(toIndex_);

            bucketLP_ = Buckets.addCollateral(
                buckets_[toIndex_],
                msg.sender,
                toBucketDeposit,
                collateralToMerge_,
                toBucketPrice
            );

            // revert if (due to rounding) the awarded LP is 0
            if (bucketLP_ == 0) revert InsufficientLP();
        }
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    /**
     *  @notice Removes max collateral amount from a given bucket index.
     *  @dev    === Write state ===
     *  @dev    decrement `lender.lps` accumulator
     *  @dev    decrement `bucket.collateral` and `bucket.lps` accumulator
     *  @dev    === Reverts on ===
     *  @dev    not enough collateral `InsufficientCollateral()`
     *  @dev    no claim `NoClaim()`
     *  @dev    no `LP` redeemed `InsufficientLP()`
     *  @dev    leaves less than dust limit in bucket `DustAmountNotExceeded()`
     *  @dev    === Emit events ===
     *  @dev    - `BucketBankruptcy`
     *  @return collateralAmount_ Amount of collateral that was removed.
     *  @return lpAmount_         Amount of `LP` redeemed for removed collateral amount.
     */
    function _removeMaxCollateral(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        uint256 dustLimit_,
        uint256 maxAmount_,
        uint256 index_
    ) internal returns (uint256 collateralAmount_, uint256 lpAmount_) {
        Bucket storage bucket = buckets_[index_];

        uint256 bucketCollateral = bucket.collateral;
        // revert if there's no collateral in bucket
        if (bucketCollateral == 0) revert InsufficientCollateral();

        Lender storage lender = bucket.lenders[msg.sender];

        uint256 lenderLpBalance;

        if (bucket.bankruptcyTime < lender.depositTime) lenderLpBalance = lender.lps;
        // revert if no LP to redeem
        if (lenderLpBalance == 0) revert NoClaim();

        uint256 bucketPrice   = _priceAt(index_);
        uint256 bucketLP     = bucket.lps;
        uint256 bucketDeposit = Deposits.valueAt(deposits_, index_);

        // limit amount by what is available in the bucket
        collateralAmount_ = Maths.min(maxAmount_, bucketCollateral);

        // determine how much LP would be required to remove the requested amount
        uint256 requiredLP = Buckets.collateralToLP(
            bucketCollateral,
            bucketLP,
            bucketDeposit,
            collateralAmount_,
            bucketPrice,
            Math.Rounding.Up
        );

        // revert if (due to rounding) the required LP is 0
        if (requiredLP == 0) revert InsufficientLP();

        // limit withdrawal by the lender's LPB
        if (requiredLP <= lenderLpBalance) {
            // withdraw collateralAmount_ as is
            lpAmount_ = requiredLP;
        } else {
            lpAmount_         = lenderLpBalance;
            collateralAmount_ = Math.mulDiv(lenderLpBalance, collateralAmount_, requiredLP);

            if (collateralAmount_ == 0) revert InsufficientLP();
        }

        // update bucket LP and collateral balance
        bucketLP -= Maths.min(bucketLP, lpAmount_);

        // If clearing out the bucket collateral, ensure it's zeroed out
        if (bucketLP == 0 && bucketDeposit == 0) collateralAmount_ = bucketCollateral;

        collateralAmount_ = Maths.min(bucketCollateral, collateralAmount_);
        bucketCollateral  -= collateralAmount_;
        if (bucketCollateral != 0 && bucketCollateral < dustLimit_) revert DustAmountNotExceeded();
        bucket.collateral = bucketCollateral;

        // check if bucket healthy after collateral remove - set bankruptcy if collateral and deposit are 0 but there's still LP
        if (bucketCollateral == 0 && bucketDeposit == 0 && bucketLP != 0) {
            bucket.lps            = 0;
            bucket.bankruptcyTime = block.timestamp;

            emit BucketBankruptcy(
                index_,
                bucketLP
            );
        } else {
            // update lender and bucket LP balances
            lender.lps -= lpAmount_;
            bucket.lps = bucketLP;
        }
    }

    /**
     *  @notice Removes the amount of quote tokens calculated for the given amount of LP.
     *  @dev    === Write state ===
     *  @dev    - `Deposits.unscaledRemove` (remove amount in `Fenwick` tree, from index):
     *  @dev      update `values` array state
     *  @dev    === Reverts on ===
     *  @dev    no `LP` redeemed `InsufficientLP()`
     *  @dev    no unscaled amount removed` `InvalidAmount()`
     *  @return removedAmount_     Amount of scaled deposit removed.
     *  @return redeemedLP_        Amount of bucket `LP` corresponding for calculated scaled deposit amount.
     *  @return unscaledRemaining_ Amount of unscaled deposit remaining.
     */
    function _removeMaxDeposit(
        DepositsState storage deposits_,
        RemoveDepositParams memory params_
    ) internal returns (uint256 removedAmount_, uint256 redeemedLP_, uint256 unscaledRemaining_) {

        uint256 unscaledDepositAvailable = Deposits.unscaledValueAt(deposits_, params_.index);

        // revert if there's no liquidity available to remove
        if (unscaledDepositAvailable == 0) revert InsufficientLiquidity();

        uint256 depositScale           = Deposits.scale(deposits_, params_.index);
        uint256 scaledDepositAvailable = Maths.wmul(unscaledDepositAvailable, depositScale);

        // Below is pseudocode explaining the logic behind finding the constrained amount of deposit and LPB
        // scaledRemovedAmount is constrained by the scaled maxAmount(in QT), the scaledDeposit constraint, and
        // the lender LPB exchange rate in scaled deposit-to-LPB for the bucket:
        // scaledRemovedAmount = min ( maxAmount_, scaledDeposit, lenderLPBalance*exchangeRate)
        // redeemedLP_ = min ( maxAmount_/scaledExchangeRate, scaledDeposit/exchangeRate, lenderLPBalance)

        uint256 scaledLpConstraint = Buckets.lpToQuoteTokens(
            params_.bucketCollateral,
            params_.bucketLP,
            scaledDepositAvailable,
            params_.lpConstraint,
            params_.price,
            Math.Rounding.Down
        );
        uint256 unscaledRemovedAmount;
        if (
            params_.depositConstraint < scaledDepositAvailable &&
            params_.depositConstraint < scaledLpConstraint
        ) {
            // depositConstraint is binding constraint
            removedAmount_ = params_.depositConstraint;
            redeemedLP_    = Buckets.quoteTokensToLP(
                params_.bucketCollateral,
                params_.bucketLP,
                scaledDepositAvailable,
                removedAmount_,
                params_.price,
                Math.Rounding.Up
            );
            redeemedLP_ = Maths.min(redeemedLP_, params_.lpConstraint);
            unscaledRemovedAmount = Maths.wdiv(removedAmount_, depositScale);
        } else if (scaledDepositAvailable < scaledLpConstraint) {
            // scaledDeposit is binding constraint
            removedAmount_ = scaledDepositAvailable;
            redeemedLP_    = Buckets.quoteTokensToLP(
                params_.bucketCollateral,
                params_.bucketLP,
                scaledDepositAvailable,
                removedAmount_,
                params_.price,
                Math.Rounding.Up
            );
            redeemedLP_ = Maths.min(redeemedLP_, params_.lpConstraint);
            unscaledRemovedAmount = unscaledDepositAvailable;
        } else {
            // redeeming all LP
            redeemedLP_    = params_.lpConstraint;
            removedAmount_ = Buckets.lpToQuoteTokens(
                params_.bucketCollateral,
                params_.bucketLP,
                scaledDepositAvailable,
                redeemedLP_,
                params_.price,
                Math.Rounding.Down
            );
            unscaledRemovedAmount = Maths.wdiv(removedAmount_, depositScale);
        }

        // If clearing out the bucket deposit, ensure it's zeroed out
        if (redeemedLP_ == params_.bucketLP) {
            removedAmount_ = scaledDepositAvailable;
            unscaledRemovedAmount = unscaledDepositAvailable;
        }

        unscaledRemaining_ = unscaledDepositAvailable - unscaledRemovedAmount;

        // revert if (due to rounding) required LP is 0
        if (redeemedLP_ == 0) revert InsufficientLP();
        // revert if calculated amount of quote to remove is 0
        if (unscaledRemovedAmount == 0) revert InvalidAmount();

        // update FenwickTree
        Deposits.unscaledRemove(deposits_, params_.index, unscaledRemovedAmount);
    }
}