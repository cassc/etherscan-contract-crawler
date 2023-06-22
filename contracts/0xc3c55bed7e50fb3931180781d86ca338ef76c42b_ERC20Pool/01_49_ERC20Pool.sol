// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 }    from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { 
    IERC20Pool,
    IERC20PoolBorrowerActions,
    IERC20PoolImmutables,
    IERC20PoolLenderActions
}                              from './interfaces/pool/erc20/IERC20Pool.sol';
import { IERC20Taker }         from './interfaces/pool/erc20/IERC20Taker.sol';

import {
    IPoolLenderActions,
    IPoolKickerActions,
    IPoolTakerActions,
    IPoolSettlerActions
}                            from './interfaces/pool/IPool.sol';
import {
    IERC3156FlashBorrower,
    IERC3156FlashLender
}                            from './interfaces/pool/IERC3156FlashLender.sol';

import {
    DrawDebtResult,
    RepayDebtResult,
    SettleParams,
    SettleResult,
    TakeResult
}                    from './interfaces/pool/commons/IPoolInternals.sol';
import { PoolState } from './interfaces/pool/commons/IPoolState.sol';

import { FlashloanablePool } from './base/FlashloanablePool.sol';

import {
    _getCollateralDustPricePrecisionAdjustment,
    _roundToScale,
    _roundUpToScale
}                                               from './libraries/helpers/PoolHelper.sol';
import { 
    _revertIfAuctionClearable,
    _revertAfterExpiry 
}                               from './libraries/helpers/RevertsHelper.sol';

import { Loans }    from './libraries/internal/Loans.sol';
import { Deposits } from './libraries/internal/Deposits.sol';
import { Maths }    from './libraries/internal/Maths.sol';

import { BorrowerActions } from './libraries/external/BorrowerActions.sol';
import { LenderActions }   from './libraries/external/LenderActions.sol';
import { SettlerActions }  from './libraries/external/SettlerActions.sol';
import { TakerActions }    from './libraries/external/TakerActions.sol';

/**
 *  @title  ERC20 Pool contract
 *  @notice Entrypoint of `ERC20` Pool actions for pool actors:
 *          - `Lenders`: add, remove and move quote tokens; transfer `LP`
 *          - `Borrowers`: draw and repay debt
 *          - `Traders`: add, remove and move quote tokens; add and remove collateral
 *          - `Kickers`: kick undercollateralized loans; settle auctions; claim bond rewards
 *          - `Bidders`: take auctioned collateral
 *          - `Reserve purchasers`: start auctions; take reserves
 *          - `Flash borrowers`: initiate flash loans on quote tokens and collateral
 *  @dev    Contract is `FlashloanablePool` with flash loan logic.
 *  @dev    Contract is base `Pool` with logic to handle `ERC20` collateral.
 *  @dev    Calls logic from external `PoolCommons`, `LenderActions`, `BorrowerActions` and `Auction` actions libraries.
 */
contract ERC20Pool is FlashloanablePool, IERC20Pool {
    using SafeERC20 for IERC20;

    /*****************/
    /*** Constants ***/
    /*****************/

    /// @dev Immutable collateral scale arg offset.
    uint256 internal constant COLLATERAL_SCALE = 93;

    /****************************/
    /*** Initialize Functions ***/
    /****************************/

    /// @inheritdoc IERC20Pool
    function initialize(
        uint256 rate_
    ) external override {
        if (isPoolInitialized) revert AlreadyInitialized();

        inflatorState.inflator       = uint208(1e18);
        inflatorState.inflatorUpdate = uint48(block.timestamp);

        interestState.interestRate       = uint208(rate_);
        interestState.interestRateUpdate = uint48(block.timestamp);

        Loans.init(loans);

        // increment initializations count to ensure these values can't be updated
        isPoolInitialized = true;
    }

    /******************/
    /*** Immutables ***/
    /******************/

    /// @inheritdoc IERC20PoolImmutables
    function collateralScale() external pure override returns (uint256) {
        return _getArgUint256(COLLATERAL_SCALE);
    }

    /// @inheritdoc IERC20Pool
    function bucketCollateralDust(uint256 bucketIndex_) external pure override returns (uint256) {
        return _bucketCollateralDust(bucketIndex_);
    }

    /***********************************/
    /*** Borrower External Functions ***/
    /***********************************/

    /**
     *  @inheritdoc IERC20PoolBorrowerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0DebtInAuction` accumulator
     *  @dev    - increment `poolBalances.pledgedCollateral` accumulator
     *  @dev    - increment `poolBalances.t0Debt` accumulator
     *  @dev    - update `t0Debt2ToCollateral` ratio only if loan not in auction, debt and collateral pre action are considered 0 if auction settled
     *  @dev    === Emit events ===
     *  @dev    - `DrawDebt`
     */
    function drawDebt(
        address borrowerAddress_,
        uint256 amountToBorrow_,
        uint256 limitIndex_,
        uint256 collateralToPledge_
    ) external nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        // ensure the borrower is not charged for additional debt that they did not receive
        amountToBorrow_     = _roundToScale(amountToBorrow_, poolState.quoteTokenScale);
        // ensure the borrower is not credited with a fractional amount of collateral smaller than the token scale
        collateralToPledge_ = _roundToScale(collateralToPledge_, _getArgUint256(COLLATERAL_SCALE));

        DrawDebtResult memory result = BorrowerActions.drawDebt(
            auctions,
            buckets,
            deposits,
            loans,
            poolState,
            _availableQuoteToken(),
            borrowerAddress_,
            amountToBorrow_,
            limitIndex_,
            collateralToPledge_
        );

        emit DrawDebt(borrowerAddress_, amountToBorrow_, collateralToPledge_, result.newLup);

        // update in memory pool state struct
        poolState.debt       = result.poolDebt;
        poolState.t0Debt     = result.t0PoolDebt;
        if (result.t0DebtInAuctionChange != 0) poolState.t0DebtInAuction -= result.t0DebtInAuctionChange;
        poolState.collateral = result.poolCollateral;

        // adjust t0Debt2ToCollateral ratio if loan not in auction
        if (!result.inAuction) {
            _updateT0Debt2ToCollateral(
                result.settledAuction ? 0 : result.debtPreAction,       // debt pre settle (for loan in auction) not taken into account
                result.debtPostAction,
                result.settledAuction ? 0 : result.collateralPreAction, // collateral pre settle (for loan in auction) not taken into account
                result.collateralPostAction
            );
        }

        // update pool interest rate state
        _updateInterestState(poolState, result.newLup);

        if (collateralToPledge_ != 0) {
            // update pool balances state
            if (result.t0DebtInAuctionChange != 0) {
                poolBalances.t0DebtInAuction = poolState.t0DebtInAuction;
            }
            poolBalances.pledgedCollateral = poolState.collateral;

            // move collateral from sender to pool
            _transferCollateralFrom(msg.sender, collateralToPledge_);
        }

        if (amountToBorrow_ != 0) {
            // update pool balances state
            poolBalances.t0Debt = poolState.t0Debt;

            // move borrowed amount from pool to sender
            _transferQuoteToken(msg.sender, amountToBorrow_);
        }
    }

    /**
     *  @inheritdoc IERC20PoolBorrowerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0Debt accumulator`
     *  @dev    - decrement `poolBalances.t0DebtInAuction accumulator`
     *  @dev    - decrement `poolBalances.pledgedCollateral accumulator`
     *  @dev    - update `t0Debt2ToCollateral` ratio only if loan not in auction, debt and collateral pre action are considered 0 if auction settled
     *  @dev    === Emit events ===
     *  @dev    - `RepayDebt`
     */
    function repayDebt(
        address borrowerAddress_,
        uint256 maxQuoteTokenAmountToRepay_,
        uint256 collateralAmountToPull_,
        address collateralReceiver_,
        uint256 limitIndex_
    ) external nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        // ensure accounting is performed using the appropriate token scale
        if (maxQuoteTokenAmountToRepay_ != type(uint256).max)
            maxQuoteTokenAmountToRepay_ = _roundToScale(maxQuoteTokenAmountToRepay_, poolState.quoteTokenScale);
        collateralAmountToPull_         = _roundToScale(collateralAmountToPull_,     _getArgUint256(COLLATERAL_SCALE));

        RepayDebtResult memory result = BorrowerActions.repayDebt(
            auctions,
            buckets,
            deposits,
            loans,
            poolState,
            borrowerAddress_,
            maxQuoteTokenAmountToRepay_,
            collateralAmountToPull_,
            limitIndex_
        );

        emit RepayDebt(borrowerAddress_, result.quoteTokenToRepay, collateralAmountToPull_, result.newLup);

        // update in memory pool state struct
        poolState.debt       = result.poolDebt;
        poolState.t0Debt     = result.t0PoolDebt;
        if (result.t0DebtInAuctionChange != 0) poolState.t0DebtInAuction -= result.t0DebtInAuctionChange;
        poolState.collateral = result.poolCollateral;

        // adjust t0Debt2ToCollateral ratio if loan not in auction
        if (!result.inAuction) {
            _updateT0Debt2ToCollateral(
                result.settledAuction ? 0 : result.debtPreAction,       // debt pre settle (for loan in auction) not taken into account
                result.debtPostAction,
                result.settledAuction ? 0 : result.collateralPreAction, // collateral pre settle (for loan in auction) not taken into account
                result.collateralPostAction
            );
        }

        // update pool interest rate state
        _updateInterestState(poolState, result.newLup);

        if (result.quoteTokenToRepay != 0) {
            // update pool balances state
            poolBalances.t0Debt = poolState.t0Debt;
            if (result.t0DebtInAuctionChange != 0) {
                poolBalances.t0DebtInAuction = poolState.t0DebtInAuction;
            }

            // move amount to repay from sender to pool
            _transferQuoteTokenFrom(msg.sender, result.quoteTokenToRepay);
        }
        if (collateralAmountToPull_ != 0) {
            // update pool balances state
            poolBalances.pledgedCollateral = poolState.collateral;

            // move collateral from pool to address specified as collateral receiver
            _transferCollateral(collateralReceiver_, collateralAmountToPull_);
        }
    }

    /*********************************/
    /*** Lender External Functions ***/
    /*********************************/

    /**
     *  @inheritdoc IERC20PoolLenderActions
     *  @dev    === Reverts on ===
     *  @dev    - `DustAmountNotExceeded()`
     *  @dev    === Emit events ===
     *  @dev    - `AddCollateral`
     */
    function addCollateral(
        uint256 amountToAdd_,
        uint256 index_,
        uint256 expiry_
    ) external override nonReentrant returns (uint256 bucketLP_) {
        _revertAfterExpiry(expiry_);
        PoolState memory poolState = _accruePoolInterest();

        // revert if the dust amount was not exceeded, but round on the scale amount
        if (amountToAdd_ != 0 && amountToAdd_ < _bucketCollateralDust(index_)) revert DustAmountNotExceeded();
        amountToAdd_ = _roundToScale(amountToAdd_, _getArgUint256(COLLATERAL_SCALE));

        bucketLP_ = LenderActions.addCollateral(
            buckets,
            deposits,
            amountToAdd_,
            index_
        );

        emit AddCollateral(msg.sender, index_, amountToAdd_, bucketLP_);

        // update pool interest rate state
        _updateInterestState(poolState, Deposits.getLup(deposits, poolState.debt));

        // move required collateral from sender to pool
        _transferCollateralFrom(msg.sender, amountToAdd_);
    }

    /**
     *  @inheritdoc IPoolLenderActions
     *  @dev    === Emit events ===
     *  @dev    - `RemoveCollateral`
     */
    function removeCollateral(
        uint256 maxAmount_,
        uint256 index_
    ) external override nonReentrant returns (uint256 removedAmount_, uint256 redeemedLP_) {
        _revertIfAuctionClearable(auctions, loans);

        PoolState memory poolState = _accruePoolInterest();

        // round the collateral amount appropriately based on token precision
        maxAmount_ = _roundToScale(maxAmount_, _getArgUint256(COLLATERAL_SCALE));

        (removedAmount_, redeemedLP_) = LenderActions.removeMaxCollateral(
            buckets,
            deposits,
            _bucketCollateralDust(index_),
            maxAmount_,
            index_
        );

        emit RemoveCollateral(msg.sender, index_, removedAmount_, redeemedLP_);

        // update pool interest rate state
        _updateInterestState(poolState, Deposits.getLup(deposits, poolState.debt));

        // move collateral from pool to lender
        _transferCollateral(msg.sender, removedAmount_);
    }

    /*******************************/
    /*** Pool Auctions Functions ***/
    /*******************************/

    /**
     *  @inheritdoc IPoolSettlerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0Debt` accumulator
     *  @dev    - decrement `poolBalances.t0DebtInAuction` accumulator
     *  @dev    - decrement `poolBalances.pledgedCollateral` accumulator
     *  @dev    - no update of `t0Debt2ToCollateral` ratio as debt and collateral pre settle are not taken into account (pre debt and pre collateral = 0)
     *  @dev     and loan is removed from auction queue only when there's no more debt (post debt = 0)
     */
    function settle(
        address borrowerAddress_,
        uint256 maxDepth_
    ) external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        SettleResult memory result = SettlerActions.settlePoolDebt(
            auctions,
            buckets,
            deposits,
            loans,
            reserveAuction,
            poolState,
            SettleParams({
                borrower:    borrowerAddress_,
                poolBalance: _getNormalizedPoolQuoteTokenBalance(),
                bucketDepth: maxDepth_
            })
        );

        _updatePostSettleState(result, poolState);
    }

    /**
     *  @inheritdoc IPoolTakerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0Debt` accumulator
     *  @dev    - decrement `poolBalances.t0DebtInAuction` accumulator
     *  @dev    - decrement `poolBalances.pledgedCollateral` accumulator
     *  @dev    - update `t0Debt2ToCollateral` ratio only if auction settled, debt and collateral pre action are considered 0
     */
    function take(
        address        borrowerAddress_,
        uint256        maxAmount_,
        address        callee_,
        bytes calldata data_
    ) external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        uint256 collateralTokenScale = _getArgUint256(COLLATERAL_SCALE);

        // round requested collateral to an amount which can actually be transferred
        maxAmount_ = _roundToScale(maxAmount_, collateralTokenScale);

        TakeResult memory result = TakerActions.take(
            auctions,
            buckets,
            deposits,
            loans,
            poolState,
            borrowerAddress_,
            maxAmount_,
            collateralTokenScale
        );
        // round quote token up to cover the cost of purchasing the collateral
        result.quoteTokenAmount = _roundUpToScale(result.quoteTokenAmount, poolState.quoteTokenScale);

        _updatePostTakeState(result, poolState);

        _transferCollateral(callee_, result.collateralAmount);

        if (data_.length != 0) {
            IERC20Taker(callee_).atomicSwapCallback(
                result.collateralAmount / collateralTokenScale,
                result.quoteTokenAmount / poolState.quoteTokenScale,
                data_
            );
        }

        _transferQuoteTokenFrom(msg.sender, result.quoteTokenAmount);
    }

    /**
     *  @inheritdoc IPoolTakerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0Debt` accumulator
     *  @dev    - decrement `poolBalances.t0DebtInAuction` accumulator
     *  @dev    - decrement `poolBalances.pledgedCollateral` accumulator
     *  @dev    - update `t0Debt2ToCollateral` ratio only if auction settled, debt and collateral pre action are considered 0
     */
    function bucketTake(
        address borrowerAddress_,
        bool    depositTake_,
        uint256 index_
    ) external override nonReentrant {

        PoolState memory poolState = _accruePoolInterest();

        TakeResult memory result = TakerActions.bucketTake(
            auctions,
            buckets,
            deposits,
            loans,
            poolState,
            borrowerAddress_,
            depositTake_,
            index_,
            _getArgUint256(COLLATERAL_SCALE)
        );

        _updatePostTakeState(result, poolState);
    }

    /***************************/
    /*** Flashloan Functions ***/
    /***************************/

    /**
     *  @inheritdoc FlashloanablePool
     *  @dev Override default implementation and allows flashloans for both quote and collateral token.
     */
    function _isFlashloanSupported(
        address token_
    ) internal virtual view override returns (bool) {
        return token_ == _getArgAddress(QUOTE_ADDRESS) || token_ == _getArgAddress(COLLATERAL_ADDRESS);
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    /**
     *  @notice Helper function to transfer amount of collateral tokens from sender to pool contract.
     *  @param  from_    Sender address.
     *  @param  amount_  Amount to transfer from sender (`WAD` precision). Scaled to collateral precision before transfer.
     */
    function _transferCollateralFrom(address from_, uint256 amount_) internal {
        // Transfer amount in favour of the pool
        uint256 transferAmount = Maths.ceilDiv(amount_, _getArgUint256(COLLATERAL_SCALE));
        IERC20(_getArgAddress(COLLATERAL_ADDRESS)).safeTransferFrom(from_, address(this), transferAmount);
    }

    /**
     *  @notice Helper function to transfer amount of collateral tokens from pool contract.
     *  @param  to_     Receiver address.
     *  @param  amount_ Amount to transfer to receiver (`WAD` precision). Scaled to collateral precision before transfer.
     */
    function _transferCollateral(address to_, uint256 amount_) internal {
        IERC20(_getArgAddress(COLLATERAL_ADDRESS)).safeTransfer(to_, amount_ / _getArgUint256(COLLATERAL_SCALE));
    }

    /**
     *  @notice Helper function to calculate the minimum amount of collateral an actor may have in a bucket.
     *  @param  bucketIndex_  Bucket index.
     *  @return Amount of collateral dust amount of the bucket.
     */
    function _bucketCollateralDust(uint256 bucketIndex_) internal pure returns (uint256) {
        // price precision adjustment will always be 0 for encumbered collateral
        uint256 pricePrecisionAdjustment = _getCollateralDustPricePrecisionAdjustment(bucketIndex_);
        // difference between the normalized scale and the collateral token's scale
        return Maths.max(_getArgUint256(COLLATERAL_SCALE), 10 ** pricePrecisionAdjustment);
    } 
}