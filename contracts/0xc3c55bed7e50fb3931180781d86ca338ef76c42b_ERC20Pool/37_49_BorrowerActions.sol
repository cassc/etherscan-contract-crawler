// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {
    AuctionsState,
    Borrower,
    Bucket,
    DepositsState,
    LoansState,
    PoolState
}                   from '../../interfaces/pool/commons/IPoolState.sol';
import {
    DrawDebtResult,
    RepayDebtResult
}                   from '../../interfaces/pool/commons/IPoolInternals.sol';

import {
    _borrowFeeRate,
    _priceAt,
    _isCollateralized
}                           from '../helpers/PoolHelper.sol';
import { 
    _revertIfPriceDroppedBelowLimit,
    _revertOnMinDebt
}                           from '../helpers/RevertsHelper.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

import { SettlerActions } from './SettlerActions.sol';

/**
    @title  BorrowerActions library
    @notice External library containing logic for for pool actors:
            - `Borrowers`: pledge collateral and draw debt; repay debt and pull collateral
 */
library BorrowerActions {

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `drawDebt` function local vars.
    struct DrawDebtLocalVars {
        bool    borrow;                // true if borrow action
        uint256 borrowerDebt;          // [WAD] borrower's accrued debt
        uint256 compensatedCollateral; // [WAD] amount of borrower collateral that is compensated with LP (NFTs only)
        uint256 t0BorrowAmount;        // [WAD] t0 amount to borrow
        uint256 t0DebtChange;          // [WAD] additional t0 debt resulted from draw debt action
        bool    pledge;                // true if pledge action
        bool    stampT0Np;             // true if loan's t0 neutral price should be restamped (when drawing debt or pledge settles auction)
    }

    /// @dev Struct used for `repayDebt` function local vars.
    struct RepayDebtLocalVars {
        uint256 borrowerDebt;          // [WAD] borrower's accrued debt
        uint256 compensatedCollateral; // [WAD] amount of borrower collateral that is compensated with LP (NFTs only)
        bool    pull;                  // true if pull action
        bool    repay;                 // true if repay action
        bool    stampT0Np;             // true if loan's t0 neutral price should be restamped (when repay settles auction or pull collateral)
        uint256 t0DebtInAuctionChange; // [WAD] t0 change amount of debt after repayment
        uint256 t0RepaidDebt;          // [WAD] t0 debt repaid
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event LoanStamped(address indexed borrowerAddress);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error AuctionActive();
    error BorrowerNotSender();
    error BorrowerUnderCollateralized();
    error InsufficientLiquidity();
    error InsufficientCollateral();
    error InvalidAmount();
    error LimitIndexExceeded();
    error NoDebt();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IERC20PoolBorrowerActions` and `IERC721PoolBorrowerActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `SettlerActions._settleAuction` (`_removeAuction`):
     *  @dev      decrement kicker locked accumulator, increment kicker claimable accumumlator
     *  @dev      decrement auctions count accumulator
     *  @dev      update auction queue state
     *  @dev    - `Loans.update` (`_upsert`):
     *  @dev      insert or update loan in loans array
     *  @dev      remove loan from loans array
     *  @dev      update borrower in `address => borrower` mapping
     *  @dev    === Reverts on ===
     *  @dev    not enough quote tokens available `InsufficientLiquidity()`
     *  @dev    borrower not sender `BorrowerNotSender()`
     *  @dev    borrower debt less than pool min debt `AmountLTMinDebt()`
     *  @dev    limit price reached `LimitIndexExceeded()`
     *  @dev    borrower cannot draw more debt `BorrowerUnderCollateralized()`
     *  @dev    === Emit events ===
     *  @dev    - `SettlerActions._settleAuction`: `AuctionNFTSettle` or `AuctionSettle`
     */
    function drawDebt(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        uint256 maxAvailable_,
        address borrowerAddress_,
        uint256 amountToBorrow_,
        uint256 limitIndex_,
        uint256 collateralToPledge_
    ) external returns (
        DrawDebtResult memory result_
    ) {
        // revert if not enough pool balance to borrow
        if (amountToBorrow_ > maxAvailable_) revert InsufficientLiquidity();

        DrawDebtLocalVars memory vars;
        vars.pledge = collateralToPledge_ != 0;
        vars.borrow = amountToBorrow_ != 0;

        // revert if no amount to pledge or borrow
        if (!vars.pledge && !vars.borrow) revert InvalidAmount();

        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        vars.borrowerDebt = Maths.wmul(borrower.t0Debt, poolState_.inflator);

        result_.inAuction           = _inAuction(auctions_, borrowerAddress_);
        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;
        result_.t0PoolDebt          = poolState_.t0Debt;
        result_.poolDebt            = poolState_.debt;
        result_.poolCollateral      = poolState_.collateral;
        result_.remainingCollateral = borrower.collateral;

        if (vars.pledge) {
            // add new amount of collateral to pledge to borrower balance
            borrower.collateral  += collateralToPledge_;

            result_.remainingCollateral += collateralToPledge_;
            result_.newLup              = Deposits.getLup(deposits_, result_.poolDebt);

            // if loan is auctioned and becomes collateralized by newly pledged collateral then settle auction
            if (
                result_.inAuction &&
                _isCollateralized(vars.borrowerDebt, borrower.collateral, result_.newLup, poolState_.poolType)
            ) {
                // stamp borrower t0Np when exiting from auction
                vars.stampT0Np = true;

                // borrower becomes re-collateralized, entire borrower debt is removed from pool auctions debt accumulator
                result_.inAuction             = false;
                result_.settledAuction        = true;
                result_.t0DebtInAuctionChange = borrower.t0Debt;

                // settle auction and update borrower's collateral with value after settlement
                (
                    result_.remainingCollateral,
                    vars.compensatedCollateral
                ) = SettlerActions._settleAuction(
                    auctions_,
                    buckets_,
                    deposits_,
                    borrowerAddress_,
                    borrower.collateral,
                    poolState_.poolType
                );
                result_.poolCollateral -= vars.compensatedCollateral;

                borrower.collateral = result_.remainingCollateral;                
            }

            // add new amount of collateral to pledge to pool balance
            result_.poolCollateral += collateralToPledge_;
        }

        if (vars.borrow) {
            // only intended recipient can borrow quote
            if (borrowerAddress_ != msg.sender) revert BorrowerNotSender();

            // an auctioned borrower in not allowed to draw more debt (even if collateralized at the new LUP) if auction is not settled
            if (result_.inAuction) revert AuctionActive();

            vars.t0BorrowAmount = Maths.ceilWdiv(amountToBorrow_, poolState_.inflator);

            // t0 debt change is t0 amount to borrow plus the origination fee
            vars.t0DebtChange = Maths.wmul(vars.t0BorrowAmount, _borrowFeeRate(poolState_.rate) + Maths.WAD);

            borrower.t0Debt += vars.t0DebtChange;

            vars.borrowerDebt = Maths.wmul(borrower.t0Debt, poolState_.inflator);

            // check that drawing debt doesn't leave borrower debt under pool min debt amount
            _revertOnMinDebt(
                loans_,
                result_.poolDebt,
                vars.borrowerDebt,
                poolState_.quoteTokenScale
            );

            // add debt change to pool's debt
            result_.t0PoolDebt += vars.t0DebtChange;
            result_.poolDebt   = Maths.wmul(result_.t0PoolDebt, poolState_.inflator);
            result_.newLup     = Deposits.getLup(deposits_, result_.poolDebt);

            // revert if borrow drives LUP price under the specified price limit
            _revertIfPriceDroppedBelowLimit(result_.newLup, limitIndex_);

            // use new lup to check borrow action won't push borrower into a state of under-collateralization
            // this check also covers the scenario when loan is already auctioned
            if (!_isCollateralized(vars.borrowerDebt, borrower.collateral, result_.newLup, poolState_.poolType)) {
                revert BorrowerUnderCollateralized();
            }

            // stamp borrower t0Np when draw debt
            vars.stampT0Np = true;
        }

        // update loan state
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower,
            borrowerAddress_,
            result_.poolDebt,
            poolState_.rate,
            result_.newLup,
            result_.inAuction,
            vars.stampT0Np
        );

        result_.debtPostAction       = borrower.t0Debt;
        result_.collateralPostAction = borrower.collateral;
    }

    /**
     *  @notice See `IERC20PoolBorrowerActions` and `IERC721PoolBorrowerActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `SettlerActions._settleAuction` (`_removeAuction`):
     *  @dev      decrement kicker locked accumulator, increment kicker claimable accumumlator
     *  @dev      decrement auctions count accumulator
     *  @dev      update auction queue state
     *  @dev    - `Loans.update` (`_upsert`):
     *  @dev      insert or update loan in loans array
     *  @dev      remove loan from loans array
     *  @dev      update borrower in `address => borrower` mapping
     *  @dev    === Reverts on ===
     *  @dev    no debt to repay `NoDebt()`
     *  @dev    borrower debt less than pool min debt `AmountLTMinDebt()`
     *  @dev    borrower not sender `BorrowerNotSender()`
     *  @dev    not enough collateral to pull `InsufficientCollateral()`
     *  @dev    limit price reached `LimitIndexExceeded()`
     *  @dev    === Emit events ===
     *  @dev    - `SettlerActions._settleAuction`: `AuctionNFTSettle` or `AuctionSettle`
     */
    function repayDebt(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        address borrowerAddress_,
        uint256 maxQuoteTokenAmountToRepay_,
        uint256 collateralAmountToPull_,
        uint256 limitIndex_
    ) external returns (
        RepayDebtResult memory result_
    ) {
        RepayDebtLocalVars memory vars;
        vars.repay = maxQuoteTokenAmountToRepay_ != 0;
        vars.pull  = collateralAmountToPull_     != 0;

        // revert if no amount to pull or repay
        if (!vars.repay && !vars.pull) revert InvalidAmount();

        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        vars.borrowerDebt = Maths.wmul(borrower.t0Debt, poolState_.inflator);

        result_.inAuction           = _inAuction(auctions_, borrowerAddress_);
        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;
        result_.t0PoolDebt          = poolState_.t0Debt;
        result_.poolDebt            = poolState_.debt;
        result_.poolCollateral      = poolState_.collateral;
        result_.remainingCollateral = borrower.collateral;

        if (vars.repay) {
            if (borrower.t0Debt == 0) revert NoDebt();

            if (maxQuoteTokenAmountToRepay_ == type(uint256).max) {
                vars.t0RepaidDebt = borrower.t0Debt;
            } else {
                vars.t0RepaidDebt = Maths.min(
                    borrower.t0Debt,
                    Maths.floorWdiv(maxQuoteTokenAmountToRepay_, poolState_.inflator)
                );
            }

            result_.t0PoolDebt        -= vars.t0RepaidDebt;
            result_.poolDebt          = Maths.wmul(result_.t0PoolDebt, poolState_.inflator);
            result_.quoteTokenToRepay = Maths.ceilWmul(vars.t0RepaidDebt,  poolState_.inflator);

            vars.borrowerDebt = Maths.wmul(borrower.t0Debt - vars.t0RepaidDebt, poolState_.inflator);

            // check that paying the loan doesn't leave borrower debt under min debt amount
            _revertOnMinDebt(
                loans_,
                result_.poolDebt,
                vars.borrowerDebt,
                poolState_.quoteTokenScale
            );

            result_.newLup = Deposits.getLup(deposits_, result_.poolDebt);

            // if loan is auctioned and becomes collateralized by repaying debt then settle auction
            if (result_.inAuction) {
                if (_isCollateralized(vars.borrowerDebt, borrower.collateral, result_.newLup, poolState_.poolType)) {
                     // stamp borrower t0Np when exiting from auction
                    vars.stampT0Np = true;

                    // borrower becomes re-collateralized, entire borrower debt is removed from pool auctions debt accumulator
                    result_.inAuction             = false;
                    result_.settledAuction        = true;
                    result_.t0DebtInAuctionChange = borrower.t0Debt;

                    // settle auction and update borrower's collateral with value after settlement
                    (
                        result_.remainingCollateral,
                        vars.compensatedCollateral
                    ) = SettlerActions._settleAuction(
                        auctions_,
                        buckets_,
                        deposits_,
                        borrowerAddress_,
                        borrower.collateral,
                        poolState_.poolType
                    );
                    result_.poolCollateral -= vars.compensatedCollateral;

                    borrower.collateral = result_.remainingCollateral;
                } else {
                    // partial repay, remove only the paid debt from pool auctions debt accumulator
                    result_.t0DebtInAuctionChange = vars.t0RepaidDebt;
                }
            }

            borrower.t0Debt -= vars.t0RepaidDebt;
        }

        if (vars.pull) {
            // only intended recipient can pull collateral
            if (borrowerAddress_ != msg.sender) revert BorrowerNotSender();

            // an auctioned borrower in not allowed to pull collateral (even if collateralized at the new LUP) if auction is not settled
            if (result_.inAuction) revert AuctionActive();

            // calculate LUP only if it wasn't calculated in repay action
            if (!vars.repay) result_.newLup = Deposits.getLup(deposits_, result_.poolDebt);

            _revertIfPriceDroppedBelowLimit(result_.newLup, limitIndex_);

            uint256 encumberedCollateral = Maths.wdiv(vars.borrowerDebt, result_.newLup);
            if (
                borrower.t0Debt != 0 && encumberedCollateral == 0 || // case when small amount of debt at a high LUP results in encumbered collateral calculated as 0
                borrower.collateral < encumberedCollateral ||
                borrower.collateral - encumberedCollateral < collateralAmountToPull_
            ) revert InsufficientCollateral();

            // stamp borrower t0Np when pull collateral action
            vars.stampT0Np = true;

            borrower.collateral -= collateralAmountToPull_;

            result_.poolCollateral -= collateralAmountToPull_;
        }

        // update loan state
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower,
            borrowerAddress_,
            result_.poolDebt,
            poolState_.rate,
            result_.newLup,
            result_.inAuction,
            vars.stampT0Np
        );

        result_.debtPostAction       = borrower.t0Debt;
        result_.collateralPostAction = borrower.collateral;
    }

    /**
     *  @notice See `IPoolBorrowerActions` for descriptions
     *  @dev    === Write state ===
     *  @dev    - `Loans.update` (`_upsert`):
     *  @dev      insert or update loan in loans array
     *  @dev      remove loan from loans array
     *  @dev      update borrower in `address => borrower` mapping
     *  @dev    === Reverts on ===
     *  @dev    auction active `AuctionActive()`
     *  @dev    loan not fully collateralized `BorrowerUnderCollateralized()`
     *  @dev    === Emit events ===
     *  @dev    - `LoanStamped`
     */
    function stampLoan(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_
    ) external returns (
        uint256 newLup_
    ) {
        // revert if loan is in auction
        if (_inAuction(auctions_, msg.sender)) revert AuctionActive();

        Borrower memory borrower = loans_.borrowers[msg.sender];

        newLup_ = Deposits.getLup(deposits_, poolState_.debt);

        // revert if loan is not fully collateralized at current LUP
        if (
            !_isCollateralized(
                Maths.wmul(borrower.t0Debt, poolState_.inflator), // current borrower debt
                borrower.collateral,
                newLup_,
                poolState_.poolType
            )
        ) revert BorrowerUnderCollateralized();

        // update loan state to stamp Neutral Price
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower,
            msg.sender,
            poolState_.debt,
            poolState_.rate,
            newLup_,
            false,          // loan not in auction
            true            // stamp Neutral Price of the loan
        );

        emit LoanStamped(msg.sender);
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @notice Returns `true` if borrower is in auction.
     *  @dev    Used to accuratley increment and decrement `t0DebtInAuction` accumulator.
     *  @param  auctions_ Struct for pool auctions state.
     *  @param  borrower_ Borrower address to check auction status for.
     *  @return `True` if borrower is in auction.
     */
    function _inAuction(
        AuctionsState storage auctions_,
        address borrower_
    ) internal view returns (bool) {
        return auctions_.liquidations[borrower_].kickTime != 0;
    }

}