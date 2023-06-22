// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {
    AuctionsState,
    Borrower,
    DepositsState,
    LoansState,
    PoolBalancesState
} from '../../interfaces/pool/commons/IPoolState.sol';

import { _minDebtAmount, _priceAt } from './PoolHelper.sol';

import { Loans }    from '../internal/Loans.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Maths }    from '../internal/Maths.sol';

    // See `IPoolErrors` for descriptions
    error AuctionNotCleared();
    error AmountLTMinDebt();
    error DustAmountNotExceeded();
    error LimitIndexExceeded();
    error RemoveDepositLockedByAuctionDebt();
    error TransactionExpired();

    /**
     *  @notice Called by `LP` removal functions assess whether or not `LP` is locked.
     *  @dev    Reverts with `RemoveDepositLockedByAuctionDebt` if debt locked.
     *  @param  t0DebtInAuction_ Pool's t0 debt currently in auction.
     *  @param  index_           The deposit index from which `LP` is attempting to be removed.
     *  @param  inflator_        The pool inflator used to properly assess t0 debt in auctions.
     */
    function _revertIfAuctionDebtLocked(
        DepositsState storage deposits_,
        uint256 t0DebtInAuction_,
        uint256 index_,
        uint256 inflator_
    ) view {
        if (t0DebtInAuction_ != 0 ) {
            // deposit in buckets within liquidation debt from the top-of-book down are frozen.
            if (index_ <= Deposits.findIndexOfSum(deposits_, Maths.wmul(t0DebtInAuction_, inflator_))) revert RemoveDepositLockedByAuctionDebt();
        } 
    }

    /**
     *  @notice Check if head auction is clearable (auction is kicked and `72` hours passed since kick time or auction still has debt but no remaining collateral).
     *  @dev    Reverts with `AuctionNotCleared` if auction is clearable.
     */
    function _revertIfAuctionClearable(
        AuctionsState storage auctions_,
        LoansState    storage loans_
    ) view {
        address head     = auctions_.head;
        uint256 kickTime = auctions_.liquidations[head].kickTime;
        if (kickTime != 0) {
            if (block.timestamp - kickTime > 72 hours) revert AuctionNotCleared();

            Borrower storage borrower = loans_.borrowers[head];
            if (borrower.t0Debt != 0 && borrower.collateral == 0) revert AuctionNotCleared();
        }
    }

    /**
     *  @notice  Check if provided price is at or above index limit provided by borrower.
     *  @notice  Prevents stale transactions and certain `MEV` manipulations.
     *  @dev     Reverts with `LimitIndexExceeded` if index limit provided exceeded.
     *  @param newPrice_   New price to be compared with given limit price (can be `LUP`, `NP`).
     *  @param limitIndex_ Limit price index provided by user creating the transaction.
     */
    function _revertIfPriceDroppedBelowLimit(
        uint256 newPrice_,
        uint256 limitIndex_
    ) pure {
        if (newPrice_ < _priceAt(limitIndex_)) revert LimitIndexExceeded();
    }

    /**
     *  @notice Check if expiration provided by user has met or exceeded current block height timestamp.
     *  @notice Prevents stale transactions interacting with the pool at potentially unfavorable prices.
     *  @dev    Reverts with `TransactionExpired` if expired.
     *  @param  expiry_ Expiration provided by user when creating the transaction.
     */
    function _revertAfterExpiry(
        uint256 expiry_
    ) view {
        if (block.timestamp > expiry_) revert TransactionExpired();
    }

    /**
     *  @notice Called when borrower debt changes, ensuring minimum debt rules are honored.
     *  @dev    Reverts with `DustAmountNotExceeded` if under dust amount or with `AmountLTMinDebt` if amount under min debt value.
     *  @param  loans_        Loans heap, used to determine loan count.
     *  @param  poolDebt_     Total pool debt, used to calculate average debt.
     *  @param  borrowerDebt_ New debt for the borrower, assuming the current transaction succeeds.
     *  @param  quoteDust_    Smallest amount of quote token when can be transferred, determined by token scale.
     */
    function _revertOnMinDebt(
        LoansState storage loans_,
        uint256 poolDebt_,
        uint256 borrowerDebt_,
        uint256 quoteDust_
    ) view {
        if (borrowerDebt_ != 0) {
            if (borrowerDebt_ < quoteDust_) revert DustAmountNotExceeded();
            uint256 loansCount = Loans.noOfLoans(loans_);
            if (loansCount >= 10)
                if (borrowerDebt_ < _minDebtAmount(poolDebt_, loansCount)) revert AmountLTMinDebt();
        }
    }