// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Math }     from '@openzeppelin/contracts/utils/math/Math.sol';
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { PoolType } from '../../interfaces/pool/IPool.sol';

import {
    AuctionsState,
    Borrower,
    Bucket,
    DepositsState,
    Kicker,
    Lender,
    Liquidation,
    LoansState,
    PoolState,
    ReserveAuctionState
}                             from '../../interfaces/pool/commons/IPoolState.sol';
import {
    KickResult,
    KickReserveAuctionParams
}                             from '../../interfaces/pool/commons/IPoolInternals.sol';

import {
    MAX_NEUTRAL_PRICE,
    _auctionPrice,
    _bondParams,
    _bpf,
    _claimableReserves,
    _isCollateralized,
    _priceAt,
    _reserveAuctionPrice
}                                   from '../helpers/PoolHelper.sol';
import {
    _revertIfPriceDroppedBelowLimit
}                                   from '../helpers/RevertsHelper.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

/**
    @title  Auctions kicker actions library
    @notice External library containing kicker actions involving auctions within pool:
            - kick undercollateralized loans; start reserve auctions
 */
library KickerActions {

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `kick` function local vars.
    struct KickLocalVars {
        uint256 borrowerDebt;       // [WAD] the accrued debt of kicked borrower
        uint256 borrowerCollateral; // [WAD] amount of kicked borrower collateral
        uint256 neutralPrice;       // [WAD] neutral price recorded in kick action
        uint256 noOfLoans;          // number of loans and auctions in pool (used to calculate MOMP)
        uint256 momp;               // [WAD] MOMP of kicked auction
        uint256 bondFactor;         // [WAD] bond factor of kicked auction
        uint256 bondSize;           // [WAD] bond size of kicked auction
        uint256 t0KickPenalty;      // [WAD] t0 debt added as kick penalty
        uint256 kickPenalty;        // [WAD] current debt added as kick penalty
    }

    /// @dev Struct used for `lenderKick` function local vars.
    struct LenderKickLocalVars {
        uint256 bucketDeposit;  // [WAD] amount of quote tokens in bucket
        uint256 bucketPrice;    // [WAD] bucket price
        uint256 entitledAmount; // [WAD] amount that lender is entitled to remove at specified index
        uint256 lenderLP;       // [WAD] LP of lender in bucket
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event Kick(address indexed borrower, uint256 debt, uint256 collateral, uint256 bond);
    event RemoveQuoteToken(address indexed lender, uint256 indexed price, uint256 amount, uint256 lpRedeemed, uint256 lup);
    event KickReserveAuction(uint256 claimableReservesRemaining, uint256 auctionPrice, uint256 currentBurnEpoch);
    event BucketBankruptcy(uint256 indexed index, uint256 lpForfeited);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error AuctionActive();
    error BorrowerOk();
    error InsufficientLiquidity();
    error InsufficientLP();
    error InvalidAmount();
    error NoReserves();
    error PriceBelowLUP();
    error ReserveAuctionTooSoon();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IPoolKickerActions` for descriptions.
     *  @return The `KickResult` struct result of the kick action.
     */
    function kick(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        address borrowerAddress_,
        uint256 limitIndex_
    ) external returns (
        KickResult memory
    ) {
        return _kick(
            auctions_,
            deposits_,
            loans_,
            poolState_,
            borrowerAddress_,
            limitIndex_,
            0
        );
    }

    /**
     *  @notice See `IPoolKickerActions` for descriptions.
     *  @dev    === Reverts on ===
     *  @dev    bucket price below current pool `LUP` `PriceBelowLUP()`
     *  @dev    insufficient deposit to kick auction `InsufficientLiquidity()`
     *  @return kickResult_ The `KickResult` struct result of the kick action.
     */
    function lenderKick(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        mapping(uint256 => Bucket) storage buckets_,
        LoansState storage loans_,
        PoolState calldata poolState_,
        uint256 index_,
        uint256 limitIndex_
    ) external returns (
        KickResult memory kickResult_
    ) {
        LenderKickLocalVars memory vars;

        vars.bucketPrice = _priceAt(index_);

        // revert if the bucket price is below current LUP
        if (vars.bucketPrice < Deposits.getLup(deposits_, poolState_.debt)) revert PriceBelowLUP();

        Bucket storage bucket = buckets_[index_];
        Lender storage lender = bucket.lenders[msg.sender];

        vars.lenderLP      = bucket.bankruptcyTime < lender.depositTime ? lender.lps : 0;
        vars.bucketDeposit = Deposits.valueAt(deposits_, index_);

        // calculate amount lender is entitled in current bucket (based on lender LP in bucket)
        vars.entitledAmount = Buckets.lpToQuoteTokens(
            bucket.collateral,
            bucket.lps,
            vars.bucketDeposit,
            vars.lenderLP,
            vars.bucketPrice,
            Math.Rounding.Down
        );

        // cap the amount entitled at bucket deposit
        if (vars.entitledAmount > vars.bucketDeposit) vars.entitledAmount = vars.bucketDeposit;

        // revert if no entitled amount
        if (vars.entitledAmount == 0) revert InsufficientLiquidity();

        // kick top borrower
        kickResult_ = _kick(
            auctions_,
            deposits_,
            loans_,
            poolState_,
            Loans.getMax(loans_).borrower,
            limitIndex_,
            vars.entitledAmount
        );
    }

    /*************************/
    /***  Reserve Auction  ***/
    /*************************/

    /**
     *  @notice See `IPoolKickerActions` for descriptions.
     *  @dev    === Write state ===
     *  @dev    update `reserveAuction.unclaimed` accumulator
     *  @dev    update `reserveAuction.kicked` timestamp state
     *  @dev    === Reverts on ===
     *  @dev    no reserves to claim `NoReserves()`
     *  @dev    === Emit events ===
     *  @dev    - `KickReserveAuction`
     *  @return kickerAward_ The `LP`s awarded to reserve auction kicker.
     */
    function kickReserveAuction(
        AuctionsState storage auctions_,
        ReserveAuctionState storage reserveAuction_,
        KickReserveAuctionParams calldata params_
    ) external returns (uint256 kickerAward_) {
        // retrieve timestamp of latest burn event and last burn timestamp
        uint256 latestBurnEpoch   = reserveAuction_.latestBurnEventEpoch;
        uint256 lastBurnTimestamp = reserveAuction_.burnEvents[latestBurnEpoch].timestamp;

        // check that at least two weeks have passed since the last reserve auction completed, and that the auction was not kicked within the past 72 hours
        if (block.timestamp < lastBurnTimestamp + 2 weeks || block.timestamp - reserveAuction_.kicked <= 72 hours) {
            revert ReserveAuctionTooSoon();
        }

        uint256 curUnclaimedAuctionReserve = reserveAuction_.unclaimed;

        uint256 claimable = _claimableReserves(
            Maths.wmul(params_.t0PoolDebt, params_.inflator),
            params_.poolSize,
            auctions_.totalBondEscrowed,
            curUnclaimedAuctionReserve,
            params_.poolBalance
        );

        kickerAward_ = Maths.wmul(0.01 * 1e18, claimable);

        curUnclaimedAuctionReserve += claimable - kickerAward_;

        if (curUnclaimedAuctionReserve == 0) revert NoReserves();

        reserveAuction_.unclaimed = curUnclaimedAuctionReserve;
        reserveAuction_.kicked    = block.timestamp;

        // increment latest burn event epoch and update burn event timestamp
        latestBurnEpoch += 1;

        reserveAuction_.latestBurnEventEpoch = latestBurnEpoch;
        reserveAuction_.burnEvents[latestBurnEpoch].timestamp = block.timestamp;

        emit KickReserveAuction(
            curUnclaimedAuctionReserve,
            _reserveAuctionPrice(block.timestamp),
            latestBurnEpoch
        );
    }

    /***************************/
    /***  Internal Functions ***/
    /***************************/

    /**
     *  @notice Called to start borrower liquidation and to update the auctions queue.
     *  @dev    === Write state ===
     *  @dev    - `_recordAuction`:
     *  @dev      `borrower -> liquidation` mapping update
     *  @dev      increment `auctions count` accumulator
     *  @dev      increment `auctions.totalBondEscrowed` accumulator
     *  @dev      updates auction queue state
     *  @dev    - `_updateEscrowedBonds`:
     *  @dev      update `locked` and `claimable` kicker accumulators
     *  @dev    - `Loans.remove`:
     *  @dev      delete borrower from `indices => borrower` address mapping
     *  @dev      remove loan from loans array
     *  @dev    === Emit events ===
     *  @dev    - `Kick`
     *  @param  auctions_        Struct for pool auctions state.
     *  @param  deposits_        Struct for pool deposits state.
     *  @param  loans_           Struct for pool loans state.
     *  @param  poolState_       Current state of the pool.
     *  @param  borrowerAddress_ Address of the borrower to kick.
     *  @param  limitIndex_      Index of the lower bound of `NP` tolerated when kicking the auction.
     *  @param  additionalDebt_  Additional debt to be used when calculating proposed `LUP`.
     *  @return kickResult_      The `KickResult` struct result of the kick action.
     */
    function _kick(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        address borrowerAddress_,
        uint256 limitIndex_,
        uint256 additionalDebt_
    ) internal returns (
        KickResult memory kickResult_
    ) {
        Liquidation storage liquidation = auctions_.liquidations[borrowerAddress_];
        // revert if liquidation is active
        if (liquidation.kickTime != 0) revert AuctionActive();

        Borrower storage borrower = loans_.borrowers[borrowerAddress_];

        kickResult_.debtPreAction       = borrower.t0Debt;
        kickResult_.collateralPreAction = borrower.collateral;
        kickResult_.t0KickedDebt        = kickResult_.debtPreAction ;

        // add amount to remove to pool debt in order to calculate proposed LUP
        // for regular kick this is the currrent LUP in pool
        // for provisional kick this simulates LUP movement with additional debt
        kickResult_.lup = Deposits.getLup(deposits_, poolState_.debt + additionalDebt_);

        KickLocalVars memory vars;
        vars.borrowerDebt       = Maths.wmul(kickResult_.t0KickedDebt, poolState_.inflator);
        vars.borrowerCollateral = kickResult_.collateralPreAction;

        // revert if kick on a collateralized borrower
        if (_isCollateralized(vars.borrowerDebt, vars.borrowerCollateral, kickResult_.lup, poolState_.poolType)) {
            revert BorrowerOk();
        }

        // calculate auction params
        // neutral price is capped at 50 * max pool price
        vars.neutralPrice = Maths.min(
            Maths.wmul(borrower.t0Np, poolState_.inflator),
            MAX_NEUTRAL_PRICE
        );
        // check if NP is not less than price at the limit index provided by the kicker - done to prevent frontrunning kick auction call with a large amount of loan
        // which will make it harder for kicker to earn a reward and more likely that the kicker is penalized
        _revertIfPriceDroppedBelowLimit(vars.neutralPrice, limitIndex_);

        vars.noOfLoans = Loans.noOfLoans(loans_) + auctions_.noOfAuctions;

        vars.momp = _priceAt(
            Deposits.findIndexOfSum(
                deposits_,
                Maths.wdiv(poolState_.debt, vars.noOfLoans * 1e18)
            )
        );

        (vars.bondFactor, vars.bondSize) = _bondParams(
            vars.borrowerDebt,
            vars.borrowerCollateral,
            vars.momp
        );

        // record liquidation info
        _recordAuction(
            auctions_,
            liquidation,
            borrowerAddress_,
            vars.bondSize,
            vars.bondFactor,
            vars.momp,
            vars.neutralPrice
        );

        // update escrowed bonds balances and get the difference needed to cover bond (after using any kick claimable funds if any)
        kickResult_.amountToCoverBond = _updateEscrowedBonds(auctions_, vars.bondSize);

        // remove kicked loan from heap
        Loans.remove(loans_, borrowerAddress_, loans_.indices[borrowerAddress_]);

        // when loan is kicked, penalty of three months of interest is added
        vars.t0KickPenalty = Maths.wdiv(Maths.wmul(kickResult_.t0KickedDebt, poolState_.rate), 4 * 1e18);
        vars.kickPenalty   = Maths.wmul(vars.t0KickPenalty, poolState_.inflator);

        kickResult_.t0PoolDebt   = poolState_.t0Debt + vars.t0KickPenalty;
        kickResult_.t0KickedDebt += vars.t0KickPenalty;

        // recalculate LUP with new pool debt (including kick penalty)
        kickResult_.poolDebt = Maths.wmul(kickResult_.t0PoolDebt, poolState_.inflator);
        kickResult_.lup      = Deposits.getLup(deposits_, kickResult_.poolDebt);

        // update borrower debt with kicked debt penalty
        borrower.t0Debt = kickResult_.t0KickedDebt;

        emit Kick(
            borrowerAddress_,
            vars.borrowerDebt + vars.kickPenalty,
            vars.borrowerCollateral,
            vars.bondSize
        );
    }

    /**
     *  @notice Updates escrowed bonds balances, reuse kicker claimable funds and calculates difference needed to cover new bond.
     *  @dev    === Write state ===
     *  @dev    update `locked` and `claimable` kicker accumulators
     *  @dev    update `totalBondEscrowed` accumulator
     *  @param  auctions_       Struct for pool auctions state.
     *  @param  bondSize_       Bond size to cover newly kicked auction.
     *  @return bondDifference_ The amount that kicker should send to pool to cover auction bond.
     */
    function _updateEscrowedBonds(
        AuctionsState storage auctions_,
        uint256 bondSize_
    ) internal returns (uint256 bondDifference_){
        Kicker storage kicker = auctions_.kickers[msg.sender];

        kicker.locked += bondSize_;

        uint256 kickerClaimable = kicker.claimable;

        if (kickerClaimable >= bondSize_) {
            // no need to update total bond escrowed as bond is covered by kicker claimable (which is already tracked by accumulator)
            kicker.claimable -= bondSize_;
        } else {
            bondDifference_  = bondSize_ - kickerClaimable;
            kicker.claimable = 0;

            // increment total bond escrowed by amount needed to cover bond difference
            auctions_.totalBondEscrowed += bondDifference_;
        }
    }

    /**
     *  @notice Saves in storage a new liquidation that was kicked.
     *  @dev    === Write state ===
     *  @dev    `borrower -> liquidation` mapping update
     *  @dev    increment auctions count accumulator
     *  @dev    updates auction queue state
     *  @param  auctions_        Struct for pool auctions state.
     *  @param  liquidation_     Struct for current auction state.
     *  @param  borrowerAddress_ Address of the borrower that is kicked.
     *  @param  bondSize_        Bond size to cover newly kicked auction.
     *  @param  bondFactor_      Bond factor of the newly kicked auction.
     *  @param  momp_            Current pool `MOMP`.
     *  @param  neutralPrice_    Current pool `Neutral Price`.
     */
    function _recordAuction(
        AuctionsState storage auctions_,
        Liquidation storage liquidation_,
        address borrowerAddress_,
        uint256 bondSize_,
        uint256 bondFactor_,
        uint256 momp_,
        uint256 neutralPrice_
    ) internal {
        // record liquidation info
        liquidation_.kicker       = msg.sender;
        liquidation_.kickTime     = uint96(block.timestamp);
        liquidation_.kickMomp     = uint96(momp_); // cannot exceed max price enforced by _priceAt() function
        liquidation_.bondSize     = SafeCast.toUint160(bondSize_);
        liquidation_.bondFactor   = SafeCast.toUint96(bondFactor_);
        liquidation_.neutralPrice = SafeCast.toUint96(neutralPrice_);

        // increment number of active auctions
        ++auctions_.noOfAuctions;

        // update auctions queue
        if (auctions_.head != address(0)) {
            // other auctions in queue, liquidation doesn't exist or overwriting.
            auctions_.liquidations[auctions_.tail].next = borrowerAddress_;
            liquidation_.prev = auctions_.tail;
        } else {
            // first auction in queue
            auctions_.head = borrowerAddress_;
        }
        // update liquidation with the new ordering
        auctions_.tail = borrowerAddress_;
    }

}