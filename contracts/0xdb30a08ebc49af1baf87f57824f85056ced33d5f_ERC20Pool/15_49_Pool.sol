// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Clone }           from '@clones/Clone.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { Multicall }       from '@openzeppelin/contracts/utils/Multicall.sol';
import { SafeERC20 }       from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 }          from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {
    IPool,
    IPoolImmutables,
    IPoolBorrowerActions,
    IPoolLPActions,
    IPoolLenderActions,
    IPoolKickerActions,
    IPoolTakerActions,
    IPoolSettlerActions,
    IPoolState,
    IPoolDerivedState,
    IERC20Token
}                                    from '../interfaces/pool/IPool.sol';
import {
    PoolState,
    AuctionsState,
    DepositsState,
    Loan,
    LoansState,
    InflatorState,
    EmaState,
    InterestState,
    PoolBalancesState,
    ReserveAuctionState,
    Bucket,
    Lender,
    Borrower,
    Kicker,
    BurnEvent,
    Liquidation
}                                   from '../interfaces/pool/commons/IPoolState.sol';
import {
    KickResult,
    SettleResult,
    TakeResult,
    RemoveQuoteParams,
    MoveQuoteParams,
    AddQuoteParams,
    KickReserveAuctionParams
}                                   from '../interfaces/pool/commons/IPoolInternals.sol';

import {
    _priceAt,
    _roundToScale
}                               from '../libraries/helpers/PoolHelper.sol';
import {
    _revertIfAuctionDebtLocked,
    _revertIfAuctionClearable,
    _revertAfterExpiry
}                               from '../libraries/helpers/RevertsHelper.sol';

import { Buckets }  from '../libraries/internal/Buckets.sol';
import { Deposits } from '../libraries/internal/Deposits.sol';
import { Loans }    from '../libraries/internal/Loans.sol';
import { Maths }    from '../libraries/internal/Maths.sol';

import { BorrowerActions } from '../libraries/external/BorrowerActions.sol';
import { LenderActions }   from '../libraries/external/LenderActions.sol';
import { LPActions }       from '../libraries/external/LPActions.sol';
import { KickerActions }   from '../libraries/external/KickerActions.sol';
import { TakerActions }    from '../libraries/external/TakerActions.sol';
import { PoolCommons }     from '../libraries/external/PoolCommons.sol';

/**
 *  @title  Pool Contract
 *  @dev    Base contract and entrypoint for commong logic of both `ERC20` and `ERC721` pools.
 */
abstract contract Pool is Clone, ReentrancyGuard, Multicall, IPool {
    using SafeERC20 for IERC20;

    /*****************/
    /*** Constants ***/
    /*****************/

    /// @dev Immutable pool type arg offset.
    uint256 internal constant POOL_TYPE          = 0;
    /// @dev Immutable `Ajna` token address arg offset.
    uint256 internal constant AJNA_ADDRESS       = 1;
    /// @dev Immutable collateral token address arg offset.
    uint256 internal constant COLLATERAL_ADDRESS = 21;
    /// @dev Immutable quote token address arg offset.
    uint256 internal constant QUOTE_ADDRESS      = 41;
    /// @dev Immutable quote token scale arg offset.
    uint256 internal constant QUOTE_SCALE        = 61;

    /***********************/
    /*** State Variables ***/
    /***********************/

    AuctionsState       internal auctions;
    DepositsState       internal deposits;
    LoansState          internal loans;
    InflatorState       internal inflatorState;
    EmaState            internal emaState;
    InterestState       internal interestState;
    PoolBalancesState   internal poolBalances;
    ReserveAuctionState internal reserveAuction;

    /// @dev deposit index -> bucket mapping
    mapping(uint256 => Bucket) internal buckets;

    bool internal isPoolInitialized;

    /// @dev owner address -> new owner address -> deposit index -> allowed amount mapping
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _lpAllowances;

    /// @dev owner address -> transferor address -> approved flag mapping
    mapping(address => mapping(address => bool)) public override approvedTransferors;

    /******************/
    /*** Immutables ***/
    /******************/

    /// @inheritdoc IPoolImmutables
    function poolType() external pure override returns (uint8) {
        return _getArgUint8(POOL_TYPE);
    }

    /// @inheritdoc IPoolImmutables
    function collateralAddress() external pure override returns (address) {
        return _getArgAddress(COLLATERAL_ADDRESS);
    }

    /// @inheritdoc IPoolImmutables
    function quoteTokenAddress() external pure override returns (address) {
        return _getArgAddress(QUOTE_ADDRESS);
    }

    /// @inheritdoc IPoolImmutables
    function quoteTokenScale() external pure override returns (uint256) {
        return _getArgUint256(QUOTE_SCALE);
    }


    /*********************************/
    /*** Lender External Functions ***/
    /*********************************/

    /// @inheritdoc IPoolLenderActions
    function addQuoteToken(
        uint256 amount_,
        uint256 index_,
        uint256 expiry_,
        bool    revertIfBelowLup_
    ) external override nonReentrant returns (uint256 bucketLP_) {
        _revertAfterExpiry(expiry_);

        _revertIfAuctionClearable(auctions, loans);

        PoolState memory poolState = _accruePoolInterest();

        // round to token precision
        amount_ = _roundToScale(amount_, poolState.quoteTokenScale);

        uint256 newLup;
        (bucketLP_, newLup) = LenderActions.addQuoteToken(
            buckets,
            deposits,
            poolState,
            AddQuoteParams({
                amount:           amount_,
                index:            index_,
                revertIfBelowLup: revertIfBelowLup_
            })
        );

        // update pool interest rate state
        _updateInterestState(poolState, newLup);

        // move quote token amount from lender to pool
        _transferQuoteTokenFrom(msg.sender, amount_);
    }

    /// @inheritdoc IPoolLenderActions
    function moveQuoteToken(
        uint256 maxAmount_,
        uint256 fromIndex_,
        uint256 toIndex_,
        uint256 expiry_,
        bool    revertIfBelowLup_
    ) external override nonReentrant returns (uint256 fromBucketLP_, uint256 toBucketLP_, uint256 movedAmount_) {
        _revertAfterExpiry(expiry_);

        _revertIfAuctionClearable(auctions, loans);

        PoolState memory poolState = _accruePoolInterest();

        _revertIfAuctionDebtLocked(deposits, poolState.t0DebtInAuction, fromIndex_, poolState.inflator);

        MoveQuoteParams memory moveParams;
        moveParams.maxAmountToMove  = maxAmount_;
        moveParams.fromIndex        = fromIndex_;
        moveParams.toIndex          = toIndex_;
        moveParams.thresholdPrice   = Loans.getMax(loans).thresholdPrice;
        moveParams.revertIfBelowLup = revertIfBelowLup_;

        uint256 newLup;
        (
            fromBucketLP_,
            toBucketLP_,
            movedAmount_,
            newLup
        ) = LenderActions.moveQuoteToken(
            buckets,
            deposits,
            poolState,
            moveParams
        );

        // update pool interest rate state
        _updateInterestState(poolState, newLup);
    }

    /// @inheritdoc IPoolLenderActions
    function removeQuoteToken(
        uint256 maxAmount_,
        uint256 index_
    ) external override nonReentrant returns (uint256 removedAmount_, uint256 redeemedLP_) {
        _revertIfAuctionClearable(auctions, loans);

        PoolState memory poolState = _accruePoolInterest();

        _revertIfAuctionDebtLocked(deposits, poolState.t0DebtInAuction, index_, poolState.inflator);

        uint256 newLup;
        (
            removedAmount_,
            redeemedLP_,
            newLup
        ) = LenderActions.removeQuoteToken(
            buckets,
            deposits,
            poolState,
            RemoveQuoteParams({
                maxAmount:      Maths.min(maxAmount_, _availableQuoteToken()),
                index:          index_,
                thresholdPrice: Loans.getMax(loans).thresholdPrice
            })
        );

        // update pool interest rate state
        _updateInterestState(poolState, newLup);

        // move quote token amount from pool to lender
        _transferQuoteToken(msg.sender, removedAmount_);
    }

    /// @inheritdoc IPoolLenderActions
    function updateInterest() external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();
        _updateInterestState(poolState, Deposits.getLup(deposits, poolState.debt));
    }

    /***********************************/
    /*** Borrower External Functions ***/
    /***********************************/

    /// @inheritdoc IPoolBorrowerActions
    function stampLoan() external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        uint256 newLup = BorrowerActions.stampLoan(
            auctions,
            deposits,
            loans,
            poolState
        );

        _updateInterestState(poolState, newLup);
    }

    /*****************************/
    /*** Liquidation Functions ***/
    /*****************************/

    /**
     *  @inheritdoc IPoolKickerActions
     *  @dev    === Write state ===
     *  @dev    increment `poolBalances.t0DebtInAuction` and `poolBalances.t0Debt` accumulators
     *  @dev    update `t0Debt2ToCollateral` ratio, debt and collateral post action are considered 0
     */
    function kick(
        address borrower_,
        uint256 npLimitIndex_
    ) external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        // kick auction
        KickResult memory result = KickerActions.kick(
            auctions,
            deposits,
            loans,
            poolState,
            borrower_,
            npLimitIndex_
        );

        // update in memory pool state struct
        poolState.debt            =  result.poolDebt;
        poolState.t0Debt          =  result.t0PoolDebt;
        poolState.t0DebtInAuction += result.t0KickedDebt;

        // adjust t0Debt2ToCollateral ratio
        _updateT0Debt2ToCollateral(
            result.debtPreAction,
            0, // debt post kick (for loan in auction) not taken into account
            result.collateralPreAction,
            0  // collateral post kick (for loan in auction) not taken into account
        );

        // update pool balances state
        poolBalances.t0Debt          = poolState.t0Debt;
        poolBalances.t0DebtInAuction = poolState.t0DebtInAuction;
        // update pool interest rate state
        _updateInterestState(poolState, result.lup);

        if (result.amountToCoverBond != 0) _transferQuoteTokenFrom(msg.sender, result.amountToCoverBond);
    }

    /**
     *  @inheritdoc IPoolKickerActions
     *  @dev    === Write state ===
     *  @dev    increment `poolBalances.t0DebtInAuction` and `poolBalances.t0Debt` accumulators
     *  @dev    update `t0Debt2ToCollateral` ratio, debt and collateral post action are considered 0
     */
    function lenderKick(
        uint256 index_,
        uint256 npLimitIndex_
    ) external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        // kick auctions
        KickResult memory result = KickerActions.lenderKick(
            auctions,
            deposits,
            buckets,
            loans,
            poolState,
            index_,
            npLimitIndex_
        );

        // update in memory pool state struct
        poolState.debt            =  result.poolDebt;
        poolState.t0Debt          =  result.t0PoolDebt;
        poolState.t0DebtInAuction += result.t0KickedDebt;

        // adjust t0Debt2ToCollateral ratio
        _updateT0Debt2ToCollateral(
            result.debtPreAction,
            0, // debt post kick (for loan in auction) not taken into account
            result.collateralPreAction,
            0 // collateral post kick (for loan in auction) not taken into account
        );

        // update pool balances state
        poolBalances.t0Debt          = poolState.t0Debt;
        poolBalances.t0DebtInAuction = poolState.t0DebtInAuction;

        // update pool interest rate state
        _updateInterestState(poolState, result.lup);

        // transfer from kicker to pool the difference to cover bond
        if (result.amountToCoverBond != 0) _transferQuoteTokenFrom(msg.sender, result.amountToCoverBond);
    }

    /**
     *  @inheritdoc IPoolKickerActions
     *  @dev    === Write state ===
     *  @dev    decrease kicker's `claimable` accumulator
     *  @dev    decrease auctions `totalBondEscrowed` accumulator
     */
    function withdrawBonds(
        address recipient_,
        uint256 maxAmount_
    ) external override nonReentrant {
        uint256 claimable = auctions.kickers[msg.sender].claimable;

        // the amount to claim is constrained by the claimable balance of sender
        // claiming escrowed bonds is not constraiend by the pool balance
        maxAmount_ = Maths.min(maxAmount_, claimable);

        // revert if no amount to claim
        if (maxAmount_ == 0) revert InsufficientLiquidity();

        // decrement total bond escrowed
        auctions.totalBondEscrowed             -= maxAmount_;
        auctions.kickers[msg.sender].claimable -= maxAmount_;

        emit BondWithdrawn(msg.sender, recipient_, maxAmount_);

        _transferQuoteToken(recipient_, maxAmount_);
    }

    /*********************************/
    /*** Reserve Auction Functions ***/
    /*********************************/

    /**
     *  @inheritdoc IPoolKickerActions
     *  @dev    === Write state ===
     *  @dev    increment `latestBurnEpoch` counter
     *  @dev    update `reserveAuction.latestBurnEventEpoch` and burn event `timestamp` state
     *  @dev    === Reverts on ===
     *  @dev    2 weeks not passed `ReserveAuctionTooSoon()`
     *  @dev    === Emit events ===
     *  @dev    - `KickReserveAuction`
     */
    function kickReserveAuction() external override nonReentrant {
        // start a new claimable reserve auction, passing in relevant parameters such as the current pool size, debt, balance, and inflator value
        uint256 kickerAward = KickerActions.kickReserveAuction(
            auctions,
            reserveAuction,
            KickReserveAuctionParams({
                poolSize:    Deposits.treeSum(deposits),
                t0PoolDebt:  poolBalances.t0Debt,
                poolBalance: _getNormalizedPoolQuoteTokenBalance(),
                inflator:    inflatorState.inflator
            })
        );

        // transfer kicker award to msg.sender
        _transferQuoteToken(msg.sender, kickerAward);
    }

    /**
     *  @inheritdoc IPoolTakerActions
     *  @dev    === Write state ===
     *  @dev    increment `reserveAuction.totalAjnaBurned` accumulator
     *  @dev    update burn event `totalInterest` and `totalBurned` accumulators
     */
    function takeReserves(
        uint256 maxAmount_
    ) external override nonReentrant returns (uint256 amount_) {
        uint256 ajnaRequired;
        (amount_, ajnaRequired) = TakerActions.takeReserves(
            reserveAuction,
            maxAmount_
        );

        // burn required number of ajna tokens to take quote from reserves
        IERC20(_getArgAddress(AJNA_ADDRESS)).safeTransferFrom(msg.sender, address(this), ajnaRequired);

        IERC20Token(_getArgAddress(AJNA_ADDRESS)).burn(ajnaRequired);

        // transfer quote token to caller
        _transferQuoteToken(msg.sender, amount_);
    }

    /*****************************/
    /*** Transfer LP Functions ***/
    /*****************************/

    /// @inheritdoc IPoolLPActions
    function increaseLPAllowance(
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external override nonReentrant {
        LPActions.increaseLPAllowance(
            _lpAllowances[msg.sender][spender_],
            spender_,
            indexes_,
            amounts_
        );
    }

    /// @inheritdoc IPoolLPActions
    function decreaseLPAllowance(
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external override nonReentrant {
        LPActions.decreaseLPAllowance(
            _lpAllowances[msg.sender][spender_],
            spender_,
            indexes_,
            amounts_
        );
    }

    /// @inheritdoc IPoolLPActions
    function revokeLPAllowance(
        address spender_,
        uint256[] calldata indexes_
    ) external override nonReentrant {
        LPActions.revokeLPAllowance(
            _lpAllowances[msg.sender][spender_],
            spender_,
            indexes_
        );
    }

    /// @inheritdoc IPoolLPActions
    function approveLPTransferors(
        address[] calldata transferors_
    ) external override {
        LPActions.approveLPTransferors(
            approvedTransferors[msg.sender],
            transferors_
        );
    }

    /// @inheritdoc IPoolLPActions
    function revokeLPTransferors(
        address[] calldata transferors_
    ) external override {
        LPActions.revokeLPTransferors(
            approvedTransferors[msg.sender],
            transferors_
        );
    }

    /// @inheritdoc IPoolLPActions
    function transferLP(
        address owner_,
        address newOwner_,
        uint256[] calldata indexes_
    ) external override nonReentrant {
        LPActions.transferLP(
            buckets,
            _lpAllowances,
            approvedTransferors,
            owner_,
            newOwner_,
            indexes_
        );
    }

    /*****************************/
    /*** Pool Helper Functions ***/
    /*****************************/

    /**
     *  @notice Accrues pool interest in current block and returns pool details.
     *  @dev    external libraries call: `PoolCommons.accrueInterest`
     *  @dev    === Write state ===
     *  @dev    - `PoolCommons.accrueInterest` - `Deposits.mult` (scale `Fenwick` tree with new interest accrued):
     *  @dev      update scaling array state 
     *  @dev    - increment `reserveAuction.totalInterestEarned` accumulator
     *  @return poolState_ Struct containing pool details.
     */
    function _accruePoolInterest() internal returns (PoolState memory poolState_) {
        poolState_.t0Debt          = poolBalances.t0Debt;
        poolState_.t0DebtInAuction = poolBalances.t0DebtInAuction;
        poolState_.collateral      = poolBalances.pledgedCollateral;
        poolState_.inflator        = inflatorState.inflator;
        poolState_.rate            = interestState.interestRate;
        poolState_.poolType        = _getArgUint8(POOL_TYPE);
        poolState_.quoteTokenScale = _getArgUint256(QUOTE_SCALE);

	    // check if t0Debt is not equal to 0, indicating that there is debt to be tracked for the pool
        if (poolState_.t0Debt != 0) {
            // Calculate prior pool debt
            poolState_.debt = Maths.wmul(poolState_.t0Debt, poolState_.inflator);

	        // calculate elapsed time since inflator was last updated
            uint256 elapsed = block.timestamp - inflatorState.inflatorUpdate;

	        // set isNewInterestAccrued field to true if elapsed time is not 0, indicating that new interest may have accrued
            poolState_.isNewInterestAccrued = elapsed != 0;

            // if new interest may have accrued, call accrueInterest function and update inflator and debt fields of poolState_ struct
            if (poolState_.isNewInterestAccrued) {
                (uint256 newInflator, uint256 newInterest) = PoolCommons.accrueInterest(
                    emaState,
                    deposits,
                    poolState_,
                    Loans.getMax(loans).thresholdPrice,
                    elapsed
                );
                poolState_.inflator = newInflator;
                // After debt owed to lenders has accrued, calculate current debt owed by borrowers
                poolState_.debt = Maths.wmul(poolState_.t0Debt, poolState_.inflator);

                // update total interest earned accumulator with the newly accrued interest
                reserveAuction.totalInterestEarned += newInterest;
            }
        }
    }

    /**
     *  @notice Helper function to update pool state post take and bucket take actions.
     *  @param result_    Struct containing details of take result.
     *  @param poolState_ Struct containing pool details.
     */
    function _updatePostTakeState(
        TakeResult memory result_,
        PoolState memory poolState_
    ) internal {
        // update in memory pool state struct
        poolState_.debt            =  result_.poolDebt;
        poolState_.t0Debt          =  result_.t0PoolDebt;
        poolState_.t0DebtInAuction += result_.t0DebtPenalty;
        poolState_.t0DebtInAuction -= result_.t0DebtInAuctionChange;
        poolState_.collateral      -= (result_.collateralAmount + result_.compensatedCollateral); // deduct collateral taken plus collateral compensated if NFT auction settled

        // adjust t0Debt2ToCollateral ratio if auction settled by take action
        if (result_.settledAuction) {
            _updateT0Debt2ToCollateral(
                0, // debt pre take (for loan in auction) not taken into account
                result_.debtPostAction,
                0, // collateral pre take (for loan in auction) not taken into account
                result_.collateralPostAction
            );
        }

        // update pool balances state
        poolBalances.t0Debt            = poolState_.t0Debt;
        poolBalances.t0DebtInAuction   = poolState_.t0DebtInAuction;
        poolBalances.pledgedCollateral = poolState_.collateral;
        // update pool interest rate state
        _updateInterestState(poolState_, result_.newLup);
    }

    /**
     *  @notice Helper function to update pool state post settle action.
     *  @param result_    Struct containing details of settle result.
     *  @param poolState_ Struct containing pool details.
     */
    function _updatePostSettleState(
        SettleResult memory result_,
        PoolState memory poolState_
    ) internal {
        // update in memory pool state struct
        poolState_.debt            -= Maths.wmul(result_.t0DebtSettled, poolState_.inflator);
        poolState_.t0Debt          -= result_.t0DebtSettled;
        poolState_.t0DebtInAuction -= result_.t0DebtSettled;
        poolState_.collateral      -= result_.collateralSettled;

        // update pool balances state
        poolBalances.t0Debt            = poolState_.t0Debt;
        poolBalances.t0DebtInAuction   = poolState_.t0DebtInAuction;
        poolBalances.pledgedCollateral = poolState_.collateral;
        // update pool interest rate state
        _updateInterestState(poolState_, Deposits.getLup(deposits, poolState_.debt));
    }

    /**
     *  @notice Adjusts the `t0` debt 2 to collateral ratio, `interestState.t0Debt2ToCollateral`.
     *  @dev    Anytime a borrower's debt or collateral changes, the `interestState.t0Debt2ToCollateral` must be updated.
     *  @dev    === Write state ===
     *  @dev    update `interestState.t0Debt2ToCollateral` accumulator
     *  @param debtPreAction_  Borrower's debt before the action
     *  @param debtPostAction_ Borrower's debt after the action
     *  @param colPreAction_   Borrower's collateral before the action
     *  @param colPostAction_  Borrower's collateral after the action
     */
    function _updateT0Debt2ToCollateral(
        uint256 debtPreAction_,
        uint256 debtPostAction_,
        uint256 colPreAction_,
        uint256 colPostAction_
    ) internal {
        uint256 debt2ColAccumPreAction  = colPreAction_  != 0 ? debtPreAction_  ** 2 / colPreAction_  : 0;
        uint256 debt2ColAccumPostAction = colPostAction_ != 0 ? debtPostAction_ ** 2 / colPostAction_ : 0;

        if (debt2ColAccumPreAction != 0 || debt2ColAccumPostAction != 0) {
            uint256 curT0Debt2ToCollateral = interestState.t0Debt2ToCollateral;
            curT0Debt2ToCollateral += debt2ColAccumPostAction;
            curT0Debt2ToCollateral -= debt2ColAccumPreAction;

            interestState.t0Debt2ToCollateral = curT0Debt2ToCollateral;
        }
    }

    /**
     *  @notice Update interest rate and inflator of the pool.
     *  @dev    external libraries call: `PoolCommons.updateInterestState`
     *  @dev    === Write state ===
     *  @dev    - `PoolCommons.updateInterestState`
     *  @dev      `EMA`s accumulators
     *  @dev      interest rate accumulator and `interestRateUpdate` state
     *  @dev      pool inflator and `inflatorUpdate` state
     *  @dev    === Emit events ===
     *  @dev    `PoolCommons.updateInterestState`: `UpdateInterestRate`
     *  @param  poolState_ Struct containing pool details.
     *  @param  lup_       Current `LUP` in pool.
     */
    function _updateInterestState(
        PoolState memory poolState_,
        uint256 lup_
    ) internal {

        PoolCommons.updateInterestState(interestState, emaState, deposits, poolState_, lup_);

        // update pool inflator
        if (poolState_.isNewInterestAccrued) {
            inflatorState.inflator       = uint208(poolState_.inflator);
            inflatorState.inflatorUpdate = uint48(block.timestamp);
        // if the debt in the current pool state is 0, also update the inflator and inflatorUpdate fields in inflatorState
        // slither-disable-next-line incorrect-equality
        } else if (poolState_.debt == 0) {
            inflatorState.inflator       = uint208(Maths.WAD);
            inflatorState.inflatorUpdate = uint48(block.timestamp);
        }
    }

    /**
     *  @notice Helper function to transfer amount of quote tokens from sender to pool contract.
     *  @param  from_    Sender address.
     *  @param  amount_  Amount to transfer from sender (`WAD` precision). Scaled to quote token precision before transfer.
     */
    function _transferQuoteTokenFrom(address from_, uint256 amount_) internal {
        // Transfer amount in favour of the pool
        uint256 transferAmount = Maths.ceilDiv(amount_, _getArgUint256(QUOTE_SCALE));
        IERC20(_getArgAddress(QUOTE_ADDRESS)).safeTransferFrom(from_, address(this), transferAmount);
    }

    /**
     *  @notice Helper function to transfer amount of quote tokens from pool contract.
     *  @param  to_     Receiver address.
     *  @param  amount_ Amount to transfer to receiver (`WAD` precision). Scaled to quote token precision before transfer.
     */
    function _transferQuoteToken(address to_, uint256 amount_) internal {
        IERC20(_getArgAddress(QUOTE_ADDRESS)).safeTransfer(to_, amount_ / _getArgUint256(QUOTE_SCALE));
    }

    /**
     *  @notice Returns the quote token amount available to take loans or to be removed from pool.
     *          Ensures claimable reserves and auction bonds are not used when taking loans.
     */
    function _availableQuoteToken() internal view returns (uint256 quoteAvailable_) {
        uint256 poolBalance     = _getNormalizedPoolQuoteTokenBalance();
        uint256 escrowedAmounts = auctions.totalBondEscrowed + reserveAuction.unclaimed;

        if (poolBalance > escrowedAmounts) quoteAvailable_ = poolBalance - escrowedAmounts;
    }

    /**
     *  @notice Returns the pool quote token balance normalized to `WAD` to be used for calculating pool reserves.
     */
    function _getNormalizedPoolQuoteTokenBalance() internal view returns (uint256) {
        return IERC20(_getArgAddress(QUOTE_ADDRESS)).balanceOf(address(this)) * _getArgUint256(QUOTE_SCALE);
    }

    /*******************************/
    /*** External View Functions ***/
    /*******************************/

    /// @inheritdoc IPoolState
    function auctionInfo(
        address borrower_
    ) external
    view override returns (
        address kicker_,
        uint256 bondFactor_,
        uint256 bondSize_,
        uint256 kickTime_,
        uint256 kickMomp_,
        uint256 neutralPrice_,
        address head_,
        address next_,
        address prev_,
        bool alreadyTaken_
    ) {
        Liquidation storage liquidation = auctions.liquidations[borrower_];
        return (
            liquidation.kicker,
            liquidation.bondFactor,
            liquidation.bondSize,
            liquidation.kickTime,
            liquidation.kickMomp,
            liquidation.neutralPrice,
            auctions.head,
            liquidation.next,
            liquidation.prev,
            liquidation.alreadyTaken
        );
    }

    /// @inheritdoc IPoolState
    function borrowerInfo(
        address borrower_
    ) external view override returns (uint256, uint256, uint256) {
        Borrower storage borrower = loans.borrowers[borrower_];
        return (
            borrower.t0Debt,
            borrower.collateral,
            borrower.t0Np
        );
    }

    /// @inheritdoc IPoolState
    function bucketInfo(
        uint256 index_
    ) external view override returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 scale = Deposits.scale(deposits, index_);
        Bucket storage bucket = buckets[index_];
        return (
            bucket.lps,
            bucket.collateral,
            bucket.bankruptcyTime,
            Maths.wmul(scale, Deposits.unscaledValueAt(deposits, index_)),
            scale
        );
    }

    /// @inheritdoc IPoolDerivedState
    function bucketExchangeRate(
        uint256 index_
    ) external view returns (uint256 exchangeRate_) {
        Bucket storage bucket = buckets[index_];

        exchangeRate_ = Buckets.getExchangeRate(
            bucket.collateral,
            bucket.lps,
            Deposits.valueAt(deposits, index_),
            _priceAt(index_)
        );
    }

    /// @inheritdoc IPoolState
    function currentBurnEpoch() external view returns (uint256) {
        return reserveAuction.latestBurnEventEpoch;
    }

    /// @inheritdoc IPoolState
    function burnInfo(uint256 burnEventEpoch_) external view returns (uint256, uint256, uint256) {
        BurnEvent storage burnEvent = reserveAuction.burnEvents[burnEventEpoch_];

        return (
            burnEvent.timestamp,
            burnEvent.totalInterest,
            burnEvent.totalBurned
        );
    }

    /// @inheritdoc IPoolState
    function debtInfo() external view returns (uint256, uint256, uint256, uint256) {
        uint256 t0Debt   = poolBalances.t0Debt;
        uint256 inflator = inflatorState.inflator;

        return (
            Maths.ceilWmul(
                t0Debt,
                PoolCommons.pendingInflator(
                    inflator,
                    inflatorState.inflatorUpdate,
                    interestState.interestRate
                )
            ),
            Maths.ceilWmul(t0Debt, inflator),
            Maths.ceilWmul(poolBalances.t0DebtInAuction, inflator),
            interestState.t0Debt2ToCollateral
        );
    }


    /// @inheritdoc IPoolDerivedState
    function depositUpToIndex(uint256 index_) external view override returns (uint256) {
        return Deposits.prefixSum(deposits, index_);
    }
    
    /// @inheritdoc IPoolDerivedState
    function depositIndex(uint256 debt_) external view override returns (uint256) {
        return Deposits.findIndexOfSum(deposits, debt_);
    }

    /// @inheritdoc IPoolDerivedState
    function depositSize() external view override returns (uint256) {
        return Deposits.treeSum(deposits);
    }

    /// @inheritdoc IPoolDerivedState
    function depositUtilization() external view override returns (uint256) {
        return PoolCommons.utilization(emaState);
    }

    /// @inheritdoc IPoolDerivedState
    function depositScale(uint256 index_) external view override returns (uint256) {
        return deposits.scaling[index_];
    }

    /// @inheritdoc IPoolState
    function emasInfo() external view override returns (uint256, uint256, uint256, uint256) {
        return (
            emaState.debtColEma,
            emaState.lupt0DebtEma,
            emaState.debtEma,
            emaState.depositEma
        );
    }

    /// @inheritdoc IPoolState
    function inflatorInfo() external view override returns (uint256, uint256) {
        return (
            inflatorState.inflator,
            inflatorState.inflatorUpdate
        );
    }

    /// @inheritdoc IPoolState
    function interestRateInfo() external view returns (uint256, uint256) {
        return (
            interestState.interestRate,
            interestState.interestRateUpdate
        );
    }

    /// @inheritdoc IPoolState
    function kickerInfo(
        address kicker_
    ) external view override returns (uint256, uint256) {
        Kicker storage kicker = auctions.kickers[kicker_];
        return(
            kicker.claimable,
            kicker.locked
        );
    }

    /// @inheritdoc IPoolState
    function lenderInfo(
        uint256 index_,
        address lender_
    ) external view override returns (uint256 lpBalance_, uint256 depositTime_) {
        Bucket storage bucket = buckets[index_];
        Lender storage lender = bucket.lenders[lender_];

        depositTime_ = lender.depositTime;
        if (bucket.bankruptcyTime < depositTime_) lpBalance_ = lender.lps;
    }

    /// @inheritdoc IPoolState
    function lpAllowance(
        uint256 index_,
        address spender_,
        address owner_
    ) external view override returns (uint256 allowance_) {
        allowance_ = _lpAllowances[owner_][spender_][index_];
    }

    /// @inheritdoc IPoolState
    function loanInfo(
        uint256 loanId_
    ) external view override returns (address, uint256) {
        Loan memory loan = Loans.getByIndex(loans, loanId_);
        return (
            loan.borrower,
            loan.thresholdPrice
        );
    }

    /// @inheritdoc IPoolState
    function loansInfo() external view override returns (address, uint256, uint256) {
        Loan memory maxLoan = Loans.getMax(loans);
        return (
            maxLoan.borrower,
            Maths.wmul(maxLoan.thresholdPrice, inflatorState.inflator),
            Loans.noOfLoans(loans)
        );
    }

    /// @inheritdoc IPoolState
    function pledgedCollateral() external view override returns (uint256) {
        return poolBalances.pledgedCollateral;
    }

    /// @inheritdoc IPoolState
    function reservesInfo() external view override returns (uint256, uint256, uint256, uint256) {
        return (
            auctions.totalBondEscrowed,
            reserveAuction.unclaimed,
            reserveAuction.kicked,
            reserveAuction.totalInterestEarned
        );
    }

    /// @inheritdoc IPoolState
    function totalAuctionsInPool() external view override returns (uint256) {
        return auctions.noOfAuctions;
    }

    /// @inheritdoc IPoolState
    function totalT0Debt() external view override returns (uint256) {
        return poolBalances.t0Debt;
    }

    /// @inheritdoc IPoolState
    function totalT0DebtInAuction() external view override returns (uint256) {
        return poolBalances.t0DebtInAuction;
    }
}