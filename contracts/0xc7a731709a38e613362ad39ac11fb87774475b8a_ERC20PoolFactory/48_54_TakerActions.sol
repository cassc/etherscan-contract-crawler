// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { PRBMathSD59x18 } from "@prb-math/contracts/PRBMathSD59x18.sol";
import { Math }           from '@openzeppelin/contracts/utils/math/Math.sol';

import { PoolType } from '../../interfaces/pool/IPool.sol';

import {
    AuctionsState,
    Borrower,
    Bucket,
    BurnEvent,
    DepositsState,
    Liquidation,
    LoansState,
    PoolState,
    ReserveAuctionState
}                        from '../../interfaces/pool/commons/IPoolState.sol';
import {
    TakeResult
}                        from '../../interfaces/pool/commons/IPoolInternals.sol';

import {
    _auctionPrice,
    _bpf,
    _isCollateralized,
    _priceAt,
    _reserveAuctionPrice,
    _roundToScale
}                           from '../helpers/PoolHelper.sol';
import { _revertOnMinDebt } from '../helpers/RevertsHelper.sol';

import { SettlerActions } from './SettlerActions.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

/**
    @title  Auction Taker Actions library
    @notice External library containing actions involving taking auctions within pool:
            - `take` and `bucketTake` auctioned collateral; take reserves
 */
library TakerActions {

    /*******************************/
    /*** Function Params Structs ***/
    /*******************************/

    /// @dev Struct used to hold `bucketTake` function params.
    struct BucketTakeParams {
        address borrower;        // borrower address to take from
        bool    depositTake;     // deposit or arb take, used by bucket take
        uint256 index;           // bucket index, used by bucket take
        uint256 inflator;        // [WAD] current pool inflator
        uint256 collateralScale; // precision of collateral token based on decimals
    }

    /// @dev Struct used to hold `take` function params.
    struct TakeParams {
        address borrower;        // borrower address to take from
        uint256 takeCollateral;  // [WAD] desired amount to take
        uint256 inflator;        // [WAD] current pool inflator
        uint256 poolType;        // pool type (ERC20 or NFT)
        uint256 collateralScale; // precision of collateral token based on decimals
    }

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `take` function local vars.
    struct TakeLocalVars {
        uint256 auctionPrice;             // [WAD] The price of auction.
        uint256 bondChange;               // [WAD] The change made on the bond size (beeing reward or penalty).
        uint256 borrowerDebt;             // [WAD] The accrued debt of auctioned borrower.
        int256  bpf;                      // The bond penalty factor.
        uint256 bucketPrice;              // [WAD] The bucket price.
        uint256 bucketScale;              // [WAD] The bucket scale.
        uint256 collateralAmount;         // [WAD] The amount of collateral taken.
        uint256 excessQuoteToken;         // [WAD] Difference of quote token that borrower receives after take (for fractional NFT only)
        uint256 factor;                   // The take factor, calculated based on bond penalty factor.
        bool    isRewarded;               // True if kicker is rewarded (auction price lower than neutral price), false if penalized (auction price greater than neutral price).
        address kicker;                   // Address of auction kicker.
        uint256 quoteTokenAmount;         // [WAD] Scaled quantity in Fenwick tree and before 1-bpf factor, paid for collateral
        uint256 t0RepayAmount;            // [WAD] The amount of debt (quote tokens) that is recovered / repayed by take t0 terms.
        uint256 t0BorrowerDebt;           // [WAD] Borrower's t0 debt.
        uint256 t0DebtPenalty;            // [WAD] Borrower's t0 penalty - 7% from current debt if intial take, 0 otherwise.
        uint256 unscaledDeposit;          // [WAD] Unscaled bucket quantity
        uint256 unscaledQuoteTokenAmount; // [WAD] The unscaled token amount that taker should pay for collateral taken.
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event BucketTake(address indexed borrower, uint256 index, uint256 amount, uint256 collateral, uint256 bondChange, bool isReward);
    event BucketTakeLPAwarded(address indexed taker, address indexed kicker, uint256 lpAwardedTaker, uint256 lpAwardedKicker);
    event Take(address indexed borrower, uint256 amount, uint256 collateral, uint256 bondChange, bool isReward);
    event ReserveAuction(uint256 claimableReservesRemaining, uint256 auctionPrice, uint256 currentBurnEpoch);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error AuctionPriceGtBucketPrice();
    error CollateralRoundingNeededButNotPossible();
    error InsufficientLiquidity();
    error InsufficientCollateral();
    error InvalidAmount();
    error NoAuction();
    error NoReserves();
    error NoReservesAuction();
    error ReserveAuctionTooSoon();
    error TakeNotPastCooldown();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IPoolTakerActions` for descriptions.
     *  @notice Performs bucket take collateral on an auction, rewards taker and kicker (if case) and updates loan info (settles auction if case).
     *  @dev    === Reverts on ===
     *  @dev    not enough collateral to take `InsufficientCollateral()`
     *  @return result_ `TakeResult` struct containing details of bucket take result.
    */
    function bucketTake(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        PoolState memory poolState_,
        address borrowerAddress_,
        bool    depositTake_,
        uint256 index_,
        uint256 collateralScale_
    ) external returns (TakeResult memory result_) {
        Borrower memory borrower = loans_.borrowers[borrowerAddress_];
        // revert if borrower's collateral is 0
        if (borrower.collateral == 0) revert InsufficientCollateral();

        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;

        // bucket take auction
        TakeLocalVars memory vars = _takeBucket(
            auctions_,
            buckets_,
            deposits_,
            borrower,
            BucketTakeParams({
                borrower:        borrowerAddress_,
                inflator:        poolState_.inflator,
                depositTake:     depositTake_,
                index:           index_,
                collateralScale: collateralScale_
            })
        );

        // update borrower after take
        borrower.collateral -= vars.collateralAmount;
        borrower.t0Debt     = vars.t0BorrowerDebt - vars.t0RepayAmount;
        // update pool params after take
        poolState_.t0Debt += vars.t0DebtPenalty;
        poolState_.t0Debt -= vars.t0RepayAmount;
        poolState_.debt   = Maths.wmul(poolState_.t0Debt, poolState_.inflator);

        // update loan after take
        (
            result_.newLup,
            result_.settledAuction,
            result_.remainingCollateral,
            result_.compensatedCollateral
        ) = _takeLoan(auctions_, buckets_, deposits_, loans_, poolState_, borrower, borrowerAddress_);

        // complete take result struct
        result_.debtPostAction       = borrower.t0Debt;
        result_.collateralPostAction = borrower.collateral;
        result_.t0PoolDebt           = poolState_.t0Debt;
        result_.poolDebt             = poolState_.debt;
        result_.collateralAmount     = vars.collateralAmount;
        result_.t0DebtPenalty        = vars.t0DebtPenalty;
        // if settled then debt in auction changed is the entire borrower debt, otherwise only repaid amount
        result_.t0DebtInAuctionChange = result_.settledAuction ? vars.t0BorrowerDebt : vars.t0RepayAmount;
    }

    /**
     *  @notice See `IPoolTakerActions` for descriptions.
     *  @notice Performs take collateral on an auction, rewards taker and kicker (if case) and updates loan info (settles auction if case).
     *  @dev    === Reverts on ===
     *  @dev    insufficient collateral to take `InsufficientCollateral()`
     *  @return result_ `TakeResult` struct containing details of take result.
    */
    function take(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        PoolState memory poolState_,
        address borrowerAddress_,
        uint256 collateral_,
        uint256 collateralScale_
    ) external returns (TakeResult memory result_) {
        // revert if no amount to take
        if (collateral_ == 0) revert InvalidAmount();

        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        if (
            // revert in case of NFT take when there isn't a full token to be taken
            (poolState_.poolType == uint8(PoolType.ERC721) && borrower.collateral < 1e18) ||
            // revert in case of ERC20 take when no collateral to be taken
            (poolState_.poolType == uint8(PoolType.ERC20)  && borrower.collateral == 0)
        ) {
            revert InsufficientCollateral();
        }

        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;

        // take auction
        TakeLocalVars memory vars = _take(
            auctions_,
            borrower,
            TakeParams({
                borrower:        borrowerAddress_,
                takeCollateral:  collateral_,
                inflator:        poolState_.inflator,
                poolType:        poolState_.poolType,
                collateralScale: collateralScale_
            })
        );

        // update borrower after take
        borrower.collateral -= vars.collateralAmount;
        borrower.t0Debt     = vars.t0BorrowerDebt - vars.t0RepayAmount;
        // update pool params after take
        poolState_.t0Debt += vars.t0DebtPenalty;
        poolState_.t0Debt -= vars.t0RepayAmount;
        poolState_.debt   = Maths.wmul(poolState_.t0Debt, poolState_.inflator);

        // update loan after take
        (
            result_.newLup,
            result_.settledAuction,
            result_.remainingCollateral,
            result_.compensatedCollateral
        ) = _takeLoan(auctions_, buckets_, deposits_, loans_, poolState_, borrower, borrowerAddress_);

        // complete take result struct
        result_.debtPostAction       = borrower.t0Debt;
        result_.collateralPostAction = borrower.collateral;
        result_.t0PoolDebt           = poolState_.t0Debt;
        result_.poolDebt             = poolState_.debt;
        result_.collateralAmount     = vars.collateralAmount;
        result_.t0DebtPenalty        = vars.t0DebtPenalty;
        result_.quoteTokenAmount     = vars.quoteTokenAmount;
        result_.excessQuoteToken     = vars.excessQuoteToken;
        // if settled then debt in auction changed is the entire borrower debt, otherwise only repaid amount
        result_.t0DebtInAuctionChange = result_.settledAuction ? vars.t0BorrowerDebt : vars.t0RepayAmount;
    }

    /*************************/
    /***  Reserve Auction  ***/
    /*************************/

    /**
     *  @notice See `IPoolTakerActions` for descriptions.
     *  @dev    === Write state ===
     *  @dev    decrement `reserveAuction.unclaimed` accumulator
     *  @dev    === Reverts on ===
     *  @dev    not kicked or `72` hours didn't pass `NoReservesAuction()`
     *  @dev    === Emit events ===
     *  @dev    - `ReserveAuction`
     */
    function takeReserves(
        ReserveAuctionState storage reserveAuction_,
        uint256 maxAmount_
    ) external returns (uint256 amount_, uint256 ajnaRequired_) {
        // revert if no amount to be taken
        if (maxAmount_ == 0) revert InvalidAmount();

        uint256 kicked = reserveAuction_.kicked;

        if (kicked != 0 && block.timestamp - kicked <= 72 hours) {
            uint256 unclaimed = reserveAuction_.unclaimed;
            uint256 price     = _reserveAuctionPrice(kicked);

            amount_       = Maths.min(unclaimed, maxAmount_);
            ajnaRequired_ = Maths.ceilWmul(amount_, price);

            unclaimed -= amount_;

            reserveAuction_.unclaimed = unclaimed;

            uint256 totalBurned = reserveAuction_.totalAjnaBurned + ajnaRequired_;
            
            // accumulate additional ajna burned
            reserveAuction_.totalAjnaBurned = totalBurned;

            uint256 burnEventEpoch = reserveAuction_.latestBurnEventEpoch;

            // record burn event information to enable querying by staking rewards
            BurnEvent storage burnEvent = reserveAuction_.burnEvents[burnEventEpoch];
            burnEvent.totalInterest = reserveAuction_.totalInterestEarned;
            burnEvent.totalBurned   = totalBurned;

            emit ReserveAuction(
                unclaimed,
                price,
                burnEventEpoch
            );
        } else {
            revert NoReservesAuction();
        }
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    /**
     *  @notice Performs take collateral on an auction and updates bond size and kicker balance accordingly.
     *  @dev    === Emit events ===
     *  @dev    - `Take`
     *  @param  auctions_ Struct for pool auctions state.
     *  @param  borrower_ Struct containing auctioned borrower details.
     *  @param  params_   Struct containing take action params details.
     *  @return vars_     Struct containing auction take vars.
    */
    function _take(
        AuctionsState storage auctions_,
        Borrower memory borrower_,
        TakeParams memory params_
    ) internal returns (TakeLocalVars memory vars_) {
        Liquidation storage liquidation = auctions_.liquidations[params_.borrower];

        vars_ = _prepareTake(
            liquidation,
            borrower_.t0Debt,
            borrower_.collateral,
            params_.inflator
        );

        // These are placeholder max values passed to calculateTakeFlows because there is no explicit bound on the
        // quote token amount in take calls (as opposed to bucketTake)
        vars_.unscaledDeposit = type(uint256).max;
        vars_.bucketScale     = Maths.WAD;

        uint256 takeableCollateral = borrower_.collateral;
        // for NFT take make sure the take flow and bond change calculation happens for the rounded collateral that can be taken
        if (params_.poolType == uint8(PoolType.ERC721)) {
            takeableCollateral = (takeableCollateral / 1e18) * 1e18;
        }

        // In the case of take, the taker binds the collateral qty but not the quote token qty
        // ugly to get take work like a bucket take -- this is the max amount of quote token from the take that could go to
        // reduce the debt of the borrower -- analagous to the amount of deposit in the bucket for a bucket take
        vars_ = _calculateTakeFlowsAndBondChange(
            Maths.min(takeableCollateral, params_.takeCollateral),
            params_.inflator,
            params_.collateralScale,
            vars_
        );

        _rewardTake(auctions_, liquidation, vars_);

        emit Take(
            params_.borrower,
            vars_.quoteTokenAmount,
            vars_.collateralAmount,
            vars_.bondChange,
            vars_.isRewarded
        );

        if (params_.poolType == uint8(PoolType.ERC721)) {
            // slither-disable-next-line divide-before-multiply
            uint256 collateralTaken = (vars_.collateralAmount / 1e18) * 1e18; // solidity rounds down, so if 2.5 it will be 2.5 / 1 = 2

            // collateral taken not a round number
            if (collateralTaken != vars_.collateralAmount) {
                if (Maths.min(borrower_.collateral, params_.takeCollateral) >= collateralTaken + 1e18) {
                    // round up collateral to take
                    collateralTaken += 1e18;

                    // taker should send additional quote tokens to cover difference between collateral needed to be taken and rounded collateral, at auction price
                    // borrower will get quote tokens for the difference between rounded collateral and collateral taken to cover debt
                    vars_.excessQuoteToken = Maths.wmul(collateralTaken - vars_.collateralAmount, vars_.auctionPrice);
                    vars_.collateralAmount = collateralTaken;
                } else {
                    // shouldn't get here, but just in case revert
                    revert CollateralRoundingNeededButNotPossible();
                }
            }
        }
    }

    /**
     *  @notice Performs bucket take collateral on an auction and rewards taker and kicker (if case).
     *  @dev    === Emit events ===
     *  @dev    - `BucketTake`
     *  @param  auctions_ Struct for pool auctions state.
     *  @param  buckets_  Struct for pool buckets state.
     *  @param  deposits_ Struct for pool deposits state.
     *  @param  borrower_ Struct containing auctioned borrower details.
     *  @param  params_   Struct containing take action details.
     *  @return vars_     Struct containing auction take vars.
    */
    function _takeBucket(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        Borrower memory borrower_,
        BucketTakeParams memory params_
    ) internal returns (TakeLocalVars memory vars_) {
        Liquidation storage liquidation = auctions_.liquidations[params_.borrower];

        vars_= _prepareTake(
            liquidation,
            borrower_.t0Debt,
            borrower_.collateral,
            params_.inflator
        );

        vars_.unscaledDeposit = Deposits.unscaledValueAt(deposits_, params_.index);

        // revert if no quote tokens in arbed bucket
        if (vars_.unscaledDeposit == 0) revert InsufficientLiquidity();

        vars_.bucketPrice  = _priceAt(params_.index);

        // cannot arb with a price lower than the auction price
        if (vars_.auctionPrice > vars_.bucketPrice) revert AuctionPriceGtBucketPrice();
        
        // if deposit take then price to use when calculating take is bucket price
        if (params_.depositTake) vars_.auctionPrice = vars_.bucketPrice;

        vars_.bucketScale = Deposits.scale(deposits_, params_.index);

        vars_ = _calculateTakeFlowsAndBondChange(
            borrower_.collateral,
            params_.inflator,
            params_.collateralScale,
            vars_
        );

        // revert if bucket deposit cannot cover at least one unit of collateral
        if (vars_.collateralAmount == 0) revert InsufficientLiquidity();

        _rewardBucketTake(
            auctions_,
            deposits_,
            buckets_,
            liquidation,
            params_.index,
            params_.depositTake,
            vars_
        );

        emit BucketTake(
            params_.borrower,
            params_.index,
            vars_.quoteTokenAmount,
            vars_.collateralAmount,
            vars_.bondChange,
            vars_.isRewarded
        );
    }

    /**
     *  @notice Performs update of an auctioned loan that was taken (using bucket or regular take).
     *  @notice If borrower becomes recollateralized then auction is settled. Update loan's state.
     *  @dev    === Reverts on ===
     *  @dev    borrower debt less than pool min debt `AmountLTMinDebt()`
     *  @param  auctions_              Struct for pool auctions state.
     *  @param  buckets_               Struct for pool buckets state.
     *  @param  deposits_              Struct for pool deposits state.
     *  @param  loans_                 Struct for pool loans state.
     *  @param  poolState_             Struct containing pool details.
     *  @param  borrower_              The borrower details owning loan that is taken.
     *  @param  borrowerAddress_       The address of the borrower.
     *  @return newLup_                The new `LUP` of pool (after debt is repaid).
     *  @return settledAuction_        True if auction is settled by the take action. (`NFT` take: rebalance borrower collateral in pool if true)
     *  @return remainingCollateral_   Borrower collateral remaining after take action. (`NFT` take: collateral to be rebalanced in case of `NFT` settlement)
     *  @return compensatedCollateral_ Amount of collateral compensated, to be deducted from pool pledged collateral accumulator.
    */
    function _takeLoan(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        PoolState memory poolState_,
        Borrower memory borrower_,
        address borrowerAddress_
    ) internal returns (
        uint256 newLup_,
        bool settledAuction_,
        uint256 remainingCollateral_,
        uint256 compensatedCollateral_
    ) {

        uint256 borrowerDebt = Maths.wmul(borrower_.t0Debt, poolState_.inflator);

        // check that taking from loan doesn't leave borrower debt under min debt amount
        _revertOnMinDebt(
            loans_,
            poolState_.debt,
            borrowerDebt,
            poolState_.quoteTokenScale
        );

        // calculate new lup with repaid debt from take
        newLup_ = Deposits.getLup(deposits_, poolState_.debt);

        remainingCollateral_ = borrower_.collateral;

        if (_isCollateralized(borrowerDebt, borrower_.collateral, newLup_, poolState_.poolType)) {
            settledAuction_ = true;

            // settle auction and update borrower's collateral with value after settlement
            (remainingCollateral_, compensatedCollateral_) = SettlerActions._settleAuction(
                auctions_,
                buckets_,
                deposits_,
                borrowerAddress_,
                borrower_.collateral,
                poolState_.poolType
            );

            borrower_.collateral = remainingCollateral_;
        }

        // update loan state, stamp borrower t0Np only when exiting from auction
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower_,
            borrowerAddress_,
            poolState_.debt,
            poolState_.rate,
            newLup_,
            !settledAuction_,
            settledAuction_ // stamp borrower t0Np if exiting from auction
        );
    }

    /**
     *  @notice Rewards actors of a regular take action.
     *  @dev    === Write state ===
     *  @dev    update liquidation `bond size` accumulator
     *  @dev    update kicker's `locked balance` accumulator
     *  @dev    update `auctions.totalBondEscrowed` accumulator
     *  @param  auctions_     Struct for pool auctions state.
     *  @param  liquidation_  Struct containing details of auction.
     *  @param  vars          Struct containing take action result details.
     */
    function _rewardTake(
        AuctionsState storage auctions_,
        Liquidation storage liquidation_,
        TakeLocalVars memory vars
    ) internal {
        if (vars.isRewarded) {
            // take is below neutralPrice, Kicker is rewarded
            liquidation_.bondSize                 += uint160(vars.bondChange);
            auctions_.kickers[vars.kicker].locked += vars.bondChange;
            auctions_.totalBondEscrowed           += vars.bondChange;
        } else {
            // take is above neutralPrice, Kicker is penalized
            vars.bondChange = Maths.min(liquidation_.bondSize, vars.bondChange);

            liquidation_.bondSize                 -= uint160(vars.bondChange);
            auctions_.kickers[vars.kicker].locked -= vars.bondChange;
            auctions_.totalBondEscrowed           -= vars.bondChange;
        }
    }

    /**
     *  @notice Rewards actors of a bucket take action.
     *  @dev    === Write state ===
     *  @dev    - `Buckets.addLenderLP`:
     *  @dev      increment taker `lender.lps` accumulator and `lender.depositTime` state
     *  @dev      increment kicker `lender.lps` accumulator and l`ender.depositTime` state
     *  @dev    - update liquidation bond size accumulator
     *  @dev    - update kicker's locked balance accumulator
     *  @dev    - update `auctions.totalBondEscrowed` accumulator
     *  @dev    - `Deposits.unscaledRemove()` (remove amount in `Fenwick` tree, from index):
     *  @dev      update `values` array state
     *  @dev    - increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev    === Emit events ===
     *  @dev    - `BucketTakeLPAwarded`
     *  @param  auctions_     Struct for pool auctions state.
     *  @param  deposits_     Struct for pool deposits state.
     *  @param  buckets_      Struct for pool buckets state.
     *  @param  liquidation_  Struct containing details of auction to be taken from.
     *  @param  bucketIndex_  Index of a bucket, likely the `HPB`, in which collateral will be deposited.
     *  @param  depositTake_  If `true` then the take will happen at an auction price equal with bucket price. Auction price is used otherwise.
     *  @param  vars          Struct containing bucket take action result details.
     */
    function _rewardBucketTake(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        mapping(uint256 => Bucket) storage buckets_,
        Liquidation storage liquidation_,
        uint256 bucketIndex_,
        bool depositTake_,
        TakeLocalVars memory vars
    ) internal {
        Bucket storage bucket = buckets_[bucketIndex_];

        uint256 bankruptcyTime = bucket.bankruptcyTime;
        uint256 scaledDeposit  = Maths.wmul(vars.unscaledDeposit, vars.bucketScale);
        uint256 totalLPReward;
        uint256 takerLPReward;
        uint256 kickerLPReward;

        // if arb take - taker is awarded collateral * (bucket price - auction price) worth (in quote token terms) units of LPB in the bucket
        if (!depositTake_) {
            takerLPReward = Buckets.quoteTokensToLP(
                bucket.collateral,
                bucket.lps,
                scaledDeposit,
                Maths.wmul(vars.collateralAmount, vars.bucketPrice - vars.auctionPrice),
                vars.bucketPrice,
                Math.Rounding.Down
            );
            totalLPReward = takerLPReward;

            Buckets.addLenderLP(bucket, bankruptcyTime, msg.sender, takerLPReward);
        }

        // the bondholder/kicker is awarded bond change worth of LPB in the bucket
        if (vars.isRewarded) {
            kickerLPReward = Buckets.quoteTokensToLP(
                bucket.collateral,
                bucket.lps,
                scaledDeposit,
                vars.bondChange,
                vars.bucketPrice,
                Math.Rounding.Down
            );
            totalLPReward  += kickerLPReward;

            Buckets.addLenderLP(bucket, bankruptcyTime, vars.kicker, kickerLPReward);
        } else {
            // take is above neutralPrice, Kicker is penalized
            vars.bondChange = Maths.min(liquidation_.bondSize, vars.bondChange);

            liquidation_.bondSize -= uint160(vars.bondChange);

            auctions_.kickers[vars.kicker].locked -= vars.bondChange;
            auctions_.totalBondEscrowed           -= vars.bondChange;
        }

        // remove quote tokens from bucket’s deposit
        Deposits.unscaledRemove(deposits_, bucketIndex_, vars.unscaledQuoteTokenAmount);

        // total rewarded LP are added to the bucket LP balance
        if (totalLPReward != 0) bucket.lps += totalLPReward;
        // collateral is added to the bucket’s claimable collateral
        bucket.collateral += vars.collateralAmount;

        emit BucketTakeLPAwarded(
            msg.sender,
            vars.kicker,
            takerLPReward,
            kickerLPReward
        );
    }

    /**
     *  @notice Utility function to validate take and calculate take's parameters.
     *  @dev    write state:
     *              - update liquidation.alreadyTaken state
     *  @dev    reverts on:
     *              - loan is not in auction NoAuction()
     *              - in 1 hour cool down period TakeNotPastCooldown()
     *  @param  liquidation_ Liquidation struct holding auction details.
     *  @param  t0Debt_      Borrower t0 debt.
     *  @param  collateral_  Borrower collateral.
     *  @param  inflator_    The pool's inflator, used to calculate borrower debt.
     *  @return vars         The prepared vars for take action.
     */
    function _prepareTake(
        Liquidation storage liquidation_,
        uint256 t0Debt_,
        uint256 collateral_,
        uint256 inflator_
    ) internal returns (TakeLocalVars memory vars) {

        uint256 kickTime = liquidation_.kickTime;
        if (kickTime == 0) revert NoAuction();
        if (block.timestamp - kickTime <= 1 hours) revert TakeNotPastCooldown();

        vars.t0BorrowerDebt = t0Debt_;

        // if first take borrower debt is increased by 7% penalty
        if (!liquidation_.alreadyTaken) {
            vars.t0DebtPenalty  = Maths.wmul(t0Debt_, 0.07 * 1e18);
            vars.t0BorrowerDebt += vars.t0DebtPenalty;

            liquidation_.alreadyTaken = true;
        }

        vars.borrowerDebt = Maths.wmul(vars.t0BorrowerDebt, inflator_);

        uint256 neutralPrice = liquidation_.neutralPrice;

        vars.auctionPrice = _auctionPrice(liquidation_.kickMomp, neutralPrice, kickTime);
        vars.bpf          = _bpf(
            vars.borrowerDebt,
            collateral_,
            neutralPrice,
            liquidation_.bondFactor,
            vars.auctionPrice
        );
        vars.factor       = uint256(1e18 - Maths.maxInt(0, vars.bpf));
        vars.kicker       = liquidation_.kicker;
        vars.isRewarded   = (vars.bpf  >= 0);
    }

    /**
     *  @notice Computes the flows of collateral, quote token between the borrower, lender and kicker.
     *  @param  totalCollateral_        Total collateral in loan.
     *  @param  inflator_               Current pool inflator.
     *  @param  vars                    TakeParams for the take/buckettake
     */
    function _calculateTakeFlowsAndBondChange(
        uint256              totalCollateral_,
        uint256              inflator_,
        uint256              collateralScale_,
        TakeLocalVars memory vars
    ) internal pure returns (
        TakeLocalVars memory
    ) {
        // price is the current auction price, which is the price paid by the LENDER for collateral
        // from the borrower point of view, the price is actually (1-bpf) * price, as the rewards to the
        // bond holder are effectively paid for by the borrower.
        uint256 borrowerPayoffFactor = (vars.isRewarded) ? Maths.WAD - uint256(vars.bpf)                       : Maths.WAD;
        uint256 borrowerPrice        = (vars.isRewarded) ? Maths.wmul(borrowerPayoffFactor, vars.auctionPrice) : vars.auctionPrice;

        // If there is no unscaled quote token bound, then we pass in max, but that cannot be scaled without an overflow.  So we check in the line below.
        vars.quoteTokenAmount = (vars.unscaledDeposit != type(uint256).max) ? Maths.wmul(vars.unscaledDeposit, vars.bucketScale) : type(uint256).max;

        uint256 borrowerCollateralValue = Maths.wmul(totalCollateral_, borrowerPrice);
        
        if (vars.quoteTokenAmount <= vars.borrowerDebt && vars.quoteTokenAmount <= borrowerCollateralValue) {
            // quote token used to purchase is constraining factor
            vars.collateralAmount         = _roundToScale(Maths.wdiv(vars.quoteTokenAmount, borrowerPrice), collateralScale_);
            vars.t0RepayAmount            = Maths.wdiv(vars.quoteTokenAmount, inflator_);
            vars.unscaledQuoteTokenAmount = vars.unscaledDeposit;

            vars.quoteTokenAmount         = Maths.wmul(vars.collateralAmount, vars.auctionPrice);

        } else if (vars.borrowerDebt <= borrowerCollateralValue) {
            // borrower debt is constraining factor
            vars.collateralAmount         = _roundToScale(Maths.wdiv(vars.borrowerDebt, borrowerPrice), collateralScale_);
            vars.t0RepayAmount            = vars.t0BorrowerDebt;
            vars.unscaledQuoteTokenAmount = Maths.wdiv(vars.borrowerDebt, vars.bucketScale);

            vars.quoteTokenAmount         = (vars.isRewarded) ? Maths.wdiv(vars.borrowerDebt, borrowerPayoffFactor) : vars.borrowerDebt;

        } else {
            // collateral available is constraint
            vars.collateralAmount         = totalCollateral_;
            vars.t0RepayAmount            = Maths.wdiv(borrowerCollateralValue, inflator_);
            vars.unscaledQuoteTokenAmount = Maths.wdiv(borrowerCollateralValue, vars.bucketScale);

            vars.quoteTokenAmount         = Maths.wmul(vars.collateralAmount, vars.auctionPrice);
        }

        if (vars.isRewarded) {
            // take is below neutralPrice, Kicker is rewarded
            vars.bondChange = Maths.wmul(vars.quoteTokenAmount, uint256(vars.bpf));
        } else {
            // take is above neutralPrice, Kicker is penalized
            vars.bondChange = Maths.wmul(vars.quoteTokenAmount, uint256(-vars.bpf));
        }

        return vars;
    }

}