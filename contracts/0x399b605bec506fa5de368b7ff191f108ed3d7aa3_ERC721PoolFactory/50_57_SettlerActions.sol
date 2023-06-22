// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { PoolType } from '../../interfaces/pool/IPool.sol';

import {
    AuctionsState,
    Borrower,
    Bucket,
    DepositsState,
    Kicker,
    Liquidation,
    LoansState,
    PoolState,
    ReserveAuctionState
}                       from '../../interfaces/pool/commons/IPoolState.sol';
import {
    SettleParams,
    SettleResult
}                       from '../../interfaces/pool/commons/IPoolInternals.sol';

import {
    _auctionPrice,
    _indexOf,
    _priceAt,
    MAX_FENWICK_INDEX,
    MIN_PRICE,
    DEPOSIT_BUFFER   
}  from '../helpers/PoolHelper.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

/**
    @title  Auction settler library
    @notice External library containing actions involving auctions within pool:
            - `settle` auctions
 */
library SettlerActions {

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `_settlePoolDebtWithDeposit` function local vars.
    struct SettleLocalVars {
        uint256 collateralUsed;     // [WAD] collateral used to settle debt
        uint256 debt;               // [WAD] debt to settle
        uint256 hpbCollateral;      // [WAD] amount of collateral in HPB bucket
        uint256 hpbUnscaledDeposit; // [WAD] unscaled amount of of quote tokens in HPB bucket before settle
        uint256 hpbLP;              // [WAD] amount of LP in HPB bucket
        uint256 index;              // index of settling bucket
        uint256 maxSettleableDebt;  // [WAD] max amount that can be settled with existing collateral
        uint256 price;              // [WAD] price of settling bucket
        uint256 scaledDeposit;      // [WAD] scaled amount of quote tokens in bucket
        uint256 scale;              // [WAD] scale of settling bucket
        uint256 unscaledDeposit;    // [WAD] unscaled amount of quote tokens in bucket
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event AuctionSettle(address indexed borrower, uint256 collateral);
    event AuctionNFTSettle(address indexed borrower, uint256 collateral, uint256 lp, uint256 index);
    event BucketBankruptcy(uint256 indexed index, uint256 lpForfeited);
    event Settle(address indexed borrower, uint256 settledDebt);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error AuctionNotClearable();
    error NoAuction();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IPoolSettlerActions` for descriptions.
     *  @notice Settles the debt of the given loan / borrower by performing following steps:
     *          1. settle debt with `HPB`s deposit, up to specified buckets depth.
     *          2. settle debt with pool reserves (if there's still debt and no collateral left after step 1).
     *          3. forgive bad debt from next `HPB`, up to remaining buckets depth (and if there's still debt after step 2).
     *  @dev    === Write state ===
     *  @dev    update borrower state
     *  @dev    === Reverts on ===
     *  @dev    loan is not in auction `NoAuction()`
     *  @dev    `72` hours didn't pass and auction still has collateral `AuctionNotClearable()`
     *  @dev    === Emit events ===
     *  @dev    - `Settle`
     *  @return result_ The `SettleResult` struct result of settle action.
     */
    function settlePoolDebt(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        ReserveAuctionState storage reserveAuction_,
        PoolState calldata poolState_,
        SettleParams memory params_
    ) external returns (SettleResult memory result_) {
        uint256 kickTime = auctions_.liquidations[params_.borrower].kickTime;
        if (kickTime == 0) revert NoAuction();

        Borrower memory borrower = loans_.borrowers[params_.borrower];
        if ((block.timestamp - kickTime < 72 hours) && (borrower.collateral != 0)) revert AuctionNotClearable();

        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;
        result_.t0DebtSettled       = borrower.t0Debt;
        result_.collateralSettled   = borrower.collateral;

        // 1. settle debt with HPB deposit
        (
            borrower.t0Debt,
            borrower.collateral,
            params_.bucketDepth
        ) = _settlePoolDebtWithDeposit(
            buckets_,
            deposits_,
            params_,
            borrower,
            poolState_.inflator
        );

        if (borrower.t0Debt != 0 && borrower.collateral == 0) {
            // 2. settle debt with pool reserves
            uint256 assets = Maths.floorWmul(poolState_.t0Debt - result_.t0DebtSettled + borrower.t0Debt, poolState_.inflator) + params_.poolBalance;

            uint256 liabilities =
                // require 1.0 + 1e-9 deposit buffer (extra margin) for deposits
                Maths.wmul(DEPOSIT_BUFFER, Deposits.treeSum(deposits_)) +
                auctions_.totalBondEscrowed +
                reserveAuction_.unclaimed;

            // settle debt from reserves (assets - liabilities) if reserves positive, round reserves down however
            if (assets > liabilities) {
                borrower.t0Debt -= Maths.min(borrower.t0Debt, Maths.floorWdiv(assets - liabilities, poolState_.inflator));
            }

            // 3. forgive bad debt from next HPB
            if (borrower.t0Debt != 0) {
                borrower.t0Debt = _forgiveBadDebt(
                    buckets_,
                    deposits_,
                    params_,
                    borrower,
                    poolState_.inflator
                );
            }
        }

        // complete result struct with debt settled
        result_.t0DebtSettled -= borrower.t0Debt;

        emit Settle(
            params_.borrower,
            result_.t0DebtSettled
        );

        // if entire debt was settled then settle auction
        if (borrower.t0Debt == 0) {
            (borrower.collateral, ) = _settleAuction(
                auctions_,
                buckets_,
                deposits_,
                params_.borrower,
                borrower.collateral,
                poolState_.poolType
            );
        }

        // complete result struct with debt and collateral post action and collateral settled
        result_.debtPostAction      = borrower.t0Debt;
        result_.collateralRemaining = borrower.collateral;
        result_.collateralSettled   -= result_.collateralRemaining;

        // update borrower state
        loans_.borrowers[params_.borrower] = borrower;
    }

    /***************************/
    /***  Internal Functions ***/
    /***************************/

    /**
     *  @notice Performs auction settle based on pool type, emits settle event and removes auction from auctions queue.
     *  @dev    === Emit events ===
     *  @dev    - `AuctionNFTSettle` or `AuctionSettle`
     *  @param  auctions_              Struct for pool auctions state.
     *  @param  buckets_               Struct for pool buckets state.
     *  @param  deposits_              Struct for pool deposits state.
     *  @param  borrowerAddress_       Address of the borrower that exits auction.
     *  @param  borrowerCollateral_    Borrower collateral amount before auction exit (in `NFT` could be fragmented as result of partial takes).
     *  @param  poolType_              Type of the pool (can be `ERC20` or `ERC721`).
     *  @return remainingCollateral_   Collateral remaining after auction is settled (same amount for `ERC20` pool, rounded collateral for `ERC721` pool).
     *  @return compensatedCollateral_ Amount of collateral compensated (`ERC721` settle only), to be deducted from pool pledged collateral accumulator. Always `0` for `ERC20` pools.
     */
    function _settleAuction(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        address borrowerAddress_,
        uint256 borrowerCollateral_,
        uint256 poolType_
    ) internal returns (uint256 remainingCollateral_, uint256 compensatedCollateral_) {

        if (poolType_ == uint8(PoolType.ERC721)) {
            uint256 lp;
            uint256 bucketIndex;

            // floor collateral of borrower
            remainingCollateral_ = (borrowerCollateral_ / Maths.WAD) * Maths.WAD;

            // if there's fraction of NFTs remaining then reward difference to borrower as LP in auction price bucket
            if (remainingCollateral_ != borrowerCollateral_) {

                // calculate the amount of collateral that should be compensated with LP
                compensatedCollateral_ = borrowerCollateral_ - remainingCollateral_;

                uint256 auctionPrice = _auctionPrice(
                    auctions_.liquidations[borrowerAddress_].kickMomp,
                    auctions_.liquidations[borrowerAddress_].neutralPrice,
                    auctions_.liquidations[borrowerAddress_].kickTime
                );

                // determine the bucket index to compensate fractional collateral
                bucketIndex = auctionPrice > MIN_PRICE ? _indexOf(auctionPrice) : MAX_FENWICK_INDEX;

                // deposit collateral in bucket and reward LP to compensate fractional collateral
                lp = Buckets.addCollateral(
                    buckets_[bucketIndex],
                    borrowerAddress_,
                    Deposits.valueAt(deposits_, bucketIndex),
                    compensatedCollateral_,
                    _priceAt(bucketIndex)
                );
            }

            emit AuctionNFTSettle(
                borrowerAddress_,
                remainingCollateral_,
                lp,
                bucketIndex
            );

        } else {
            remainingCollateral_ = borrowerCollateral_;

            emit AuctionSettle(
                borrowerAddress_,
                remainingCollateral_
            );
        }

        _removeAuction(auctions_, borrowerAddress_);
    }

    /**
     *  @notice Removes auction and repairs the queue order.
     *  @notice Updates kicker's claimable balance with bond size awarded and subtracts bond size awarded from `liquidationBondEscrowed`.
     *  @dev    === Write state ===
     *  @dev    decrement kicker locked accumulator, increment kicker claimable accumumlator
     *  @dev    decrement auctions count accumulator
     *  @dev    update auction queue state
     *  @param  auctions_ Struct for pool auctions state.
     *  @param  borrower_ Auctioned borrower address.
     */
    function _removeAuction(
        AuctionsState storage auctions_,
        address borrower_
    ) internal {
        Liquidation memory liquidation = auctions_.liquidations[borrower_];
        // update kicker balances
        Kicker storage kicker = auctions_.kickers[liquidation.kicker];

        kicker.locked    -= liquidation.bondSize;
        kicker.claimable += liquidation.bondSize;

        // decrement number of active auctions
        -- auctions_.noOfAuctions;

        // update auctions queue
        if (auctions_.head == borrower_ && auctions_.tail == borrower_) {
            // liquidation is the head and tail
            auctions_.head = address(0);
            auctions_.tail = address(0);
        }
        else if(auctions_.head == borrower_) {
            // liquidation is the head
            auctions_.liquidations[liquidation.next].prev = address(0);
            auctions_.head = liquidation.next;
        }
        else if(auctions_.tail == borrower_) {
            // liquidation is the tail
            auctions_.liquidations[liquidation.prev].next = address(0);
            auctions_.tail = liquidation.prev;
        }
        else {
            // liquidation is in the middle
            auctions_.liquidations[liquidation.prev].next = liquidation.next;
            auctions_.liquidations[liquidation.next].prev = liquidation.prev;
        }
        // delete liquidation
        delete auctions_.liquidations[borrower_];
    }

    /**
     *  @notice Called to settle debt using `HPB` deposits, up to the number of specified buckets depth.
     *  @dev    === Write state ===
     *  @dev    - `Deposits.unscaledRemove()` (remove amount in `Fenwick` tree, from index):
     *  @dev      update `values` array state
     *  @dev    - `Buckets.addCollateral`:
     *  @dev      increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev      increment `lender.lps` accumulator and `lender.depositTime` state
     *  @dev    === Emit events ===
     *  @dev    - `BucketBankruptcy`
     *  @param  buckets_             Struct for pool buckets state.
     *  @param  deposits_            Struct for pool deposits state.
     *  @param  params_              Struct containing params for settle action.
     *  @param  borrower_            Struct containing borrower details.
     *  @param  inflator_            Current pool inflator.
     *  @return remainingt0Debt_     Remaining borrower `t0` debt after settle with `HPB`.
     *  @return remainingCollateral_ Remaining borrower collateral after settle with `HPB`.
     *  @return bucketDepth_         Number of buckets to use for forgiving debt in case there's more remaining.
     */
    function _settlePoolDebtWithDeposit(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        SettleParams memory params_,
        Borrower memory borrower_,
        uint256 inflator_
    ) internal returns (uint256 remainingt0Debt_, uint256 remainingCollateral_, uint256 bucketDepth_) {
        remainingt0Debt_     = borrower_.t0Debt;
        remainingCollateral_ = borrower_.collateral;
        bucketDepth_         = params_.bucketDepth;

        while (bucketDepth_ != 0 && remainingt0Debt_ != 0 && remainingCollateral_ != 0) {
            SettleLocalVars memory vars;

            (vars.index, , vars.scale) = Deposits.findIndexAndSumOfSum(deposits_, 1);
            vars.hpbUnscaledDeposit    = Deposits.unscaledValueAt(deposits_, vars.index);
            vars.unscaledDeposit       = vars.hpbUnscaledDeposit;
            vars.price                 = _priceAt(vars.index);

            if (vars.unscaledDeposit != 0) {
                vars.debt              = Maths.wmul(remainingt0Debt_, inflator_);           // current debt to be settled
                vars.maxSettleableDebt = Maths.floorWmul(remainingCollateral_, vars.price); // max debt that can be settled with existing collateral
                vars.scaledDeposit     = Maths.wmul(vars.scale, vars.unscaledDeposit);

                // 1) bucket deposit covers remaining loan debt to settle, loan's collateral can cover remaining loan debt to settle
                if (vars.scaledDeposit >= vars.debt && vars.maxSettleableDebt >= vars.debt) {
                    // remove only what's needed to settle the debt
                    vars.unscaledDeposit = Maths.wdiv(vars.debt, vars.scale);
                    vars.collateralUsed  = Maths.ceilWdiv(vars.debt, vars.price);

                    // settle the entire debt
                    remainingt0Debt_ = 0;
                }
                // 2) bucket deposit can not cover all of loan's remaining debt, bucket deposit is the constraint
                else if (vars.maxSettleableDebt >= vars.scaledDeposit) {
                    vars.collateralUsed = Maths.ceilWdiv(vars.scaledDeposit, vars.price);

                    // subtract from debt the corresponding t0 amount of deposit
                    remainingt0Debt_ -= Maths.floorWdiv(vars.scaledDeposit, inflator_);
                }
                // 3) loan's collateral can not cover remaining loan debt to settle, loan collateral is the constraint
                else {
                    vars.unscaledDeposit = Maths.wdiv(vars.maxSettleableDebt, vars.scale);
                    vars.collateralUsed  = remainingCollateral_;

                    remainingt0Debt_ -= Maths.floorWdiv(vars.maxSettleableDebt, inflator_);
                }

                // remove settled collateral from loan
                remainingCollateral_ -= vars.collateralUsed;

                // use HPB bucket to swap loan collateral for loan debt
                Bucket storage hpb = buckets_[vars.index];
                vars.hpbLP         = hpb.lps;
                vars.hpbCollateral = hpb.collateral + vars.collateralUsed;

                // set amount to remove as min of calculated amount and available deposit (to prevent rounding issues)
                vars.unscaledDeposit    = Maths.min(vars.hpbUnscaledDeposit, vars.unscaledDeposit);
                vars.hpbUnscaledDeposit -= vars.unscaledDeposit;

                // remove amount to settle debt from bucket (could be entire deposit or only the settled debt)
                Deposits.unscaledRemove(deposits_, vars.index, vars.unscaledDeposit);

                // check if bucket healthy - set bankruptcy if collateral is 0 and entire deposit was used to settle and there's still LP
                if (vars.hpbCollateral == 0 && vars.hpbUnscaledDeposit == 0 && vars.hpbLP != 0) {
                    hpb.lps            = 0;
                    hpb.bankruptcyTime = block.timestamp;

                    emit BucketBankruptcy(
                        vars.index,
                        vars.hpbLP
                    );
                } else {
                    // add settled collateral into bucket
                    hpb.collateral = vars.hpbCollateral;
                }

            } else {
                // Deposits in the tree is zero, insert entire collateral into lowest bucket 7388
                Buckets.addCollateral(
                    buckets_[vars.index],
                    params_.borrower,
                    0,  // zero deposit in bucket
                    remainingCollateral_,
                    vars.price
                );
                // entire collateral added into bucket, no borrower pledged collateral remaining
                remainingCollateral_ = 0;
            }

            --bucketDepth_;
        }
    }

    /**
     *  @notice Called to forgive bad debt starting from next `HPB`, up to the number of remaining buckets depth.
     *  @dev    === Write state ===
     *  @dev    - `Deposits.unscaledRemove()` (remove amount in `Fenwick` tree, from index):
     *  @dev      update `values` array state
     *  @dev      reset `bucket.lps` accumulator and update `bucket.bankruptcyTime`
     *  @dev    === Emit events ===
     *  @dev    - `BucketBankruptcy`
     *  @param  buckets_         Struct for pool buckets state.
     *  @param  deposits_        Struct for pool deposits state.
     *  @param  params_          Struct containing params for settle action.
     *  @param  borrower_        Struct containing borrower details.
     *  @param  inflator_        Current pool inflator.
     *  @return remainingt0Debt_ Remaining borrower `t0` debt after forgiving bad debt in case not enough buckets used.
     */
    function _forgiveBadDebt(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        SettleParams memory params_,
        Borrower memory borrower_,
        uint256 inflator_
    ) internal returns (uint256 remainingt0Debt_) {
        remainingt0Debt_ = borrower_.t0Debt;

        // loop through remaining buckets if there's still debt to forgive
        while (params_.bucketDepth != 0 && remainingt0Debt_ != 0) {

            (uint256 index, , uint256 scale) = Deposits.findIndexAndSumOfSum(deposits_, 1);
            uint256 unscaledDeposit          = Deposits.unscaledValueAt(deposits_, index);
            uint256 depositToRemove          = Maths.wmul(scale, unscaledDeposit);
            uint256 debt                     = Maths.wmul(remainingt0Debt_, inflator_);
            uint256 depositRemaining;

            // 1) bucket deposit covers entire loan debt to settle, no constraints needed
            if (depositToRemove >= debt) {
                // no remaining debt to forgive
                remainingt0Debt_ = 0;

                uint256 depositUsed = Maths.wdiv(debt, scale);
                depositRemaining = unscaledDeposit - depositUsed;

                // Remove deposit used to forgive bad debt from bucket
                Deposits.unscaledRemove(deposits_, index, depositUsed);

            // 2) loan debt to settle exceeds bucket deposit, bucket deposit is the constraint
            } else {
                // subtract from remaining debt the corresponding t0 amount of deposit
                remainingt0Debt_ -= Maths.floorWdiv(depositToRemove, inflator_);

                // Remove all deposit from bucket
                Deposits.unscaledRemove(deposits_, index, unscaledDeposit);
            }

            Bucket storage hpbBucket = buckets_[index];
            uint256 bucketLP = hpbBucket.lps;
            // If the remaining deposit and resulting bucket collateral is so small that the exchange rate
            // rounds to 0, then bankrupt the bucket.  Note that lhs are WADs, so the
            // quantity is naturally 1e18 times larger than the actual product
            if (depositRemaining * Maths.WAD + hpbBucket.collateral * _priceAt(index) <= bucketLP) {
                // existing LP for the bucket shall become unclaimable
                hpbBucket.lps            = 0;
                hpbBucket.bankruptcyTime = block.timestamp;

                emit BucketBankruptcy(
                    index,
                    bucketLP
                );
            }

            --params_.bucketDepth;
        }
    }

}