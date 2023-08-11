// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {
    AuctionsState,
    Borrower,
    DepositsState,
    Loan,
    LoansState
} from '../../interfaces/pool/commons/IPoolState.sol';

import { _priceAt } from '../helpers/PoolHelper.sol';

import { Deposits } from './Deposits.sol';
import { Maths }    from './Maths.sol';

/**
    @title  Loans library
    @notice Internal library containing common logic for loans management.
    @dev    The `Loans` heap is a `Max Heap` data structure (complete binary tree), the root node is the loan with the highest threshold price (`TP`)
            at a given time. The heap is represented as an array, where the first element is a dummy element (`Loan(address(0), 0)`) and the first
            value of the heap starts at index `1`, `ROOT_INDEX`. The threshold price of a loan's parent is always greater than or equal to the
            threshold price of the loan.
    @dev    This code was modified from the following source: https://github.com/zmitton/eth-heap/blob/master/contracts/Heap.sol
 */
library Loans {

    uint256 constant ROOT_INDEX = 1;

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error ZeroThresholdPrice();

    /***********************/
    /***  Initialization ***/
    /***********************/

    /**
     *  @notice Initializes Loans Max Heap.
     *  @dev    Organizes loans so `Highest Threshold Price` can be retrieved easily.
     *  @param  loans_ Holds Loan heap data.
     */
    function init(LoansState storage loans_) internal {
        loans_.loans.push(Loan(address(0), 0));
    }

    /***********************************/
    /***  Loans Management Functions ***/
    /***********************************/

    /**
     *  @notice Updates a loan: updates heap (`upsert` if `TP` not `0`, `remove` otherwise) and borrower balance.
     *  @dev    === Write state ===
     *  @dev    - `_upsert`:
     *  @dev      insert or update loan in `loans` array
     *  @dev    - `remove`:
     *  @dev      remove loan from `loans` array
     *  @dev    - update borrower in `address => borrower` mapping
     *  @param loans_           Holds loans heap data.
     *  @param auctions_        Struct for pool auctions state.
     *  @param deposits_        Struct for pool deposits state.
     *  @param borrower_        Borrower struct with borrower details.
     *  @param borrowerAddress_ Borrower's address to update.
     *  @param poolDebt_        Pool's current debt.
     *  @param poolRate_        Pool's current rate.
     *  @param lup_             Current LUP.
     *  @param inAuction_       Whether the loan is in auction or not.
     *  @param t0NpUpdate_      Whether the neutral price of borrower should be updated or not.
     */
    function update(
        LoansState storage loans_,
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        Borrower memory borrower_,
        address borrowerAddress_,
        uint256 poolDebt_,
        uint256 poolRate_,
        uint256 lup_,
        bool inAuction_,
        bool t0NpUpdate_
    ) internal {

        bool activeBorrower = borrower_.t0Debt != 0 && borrower_.collateral != 0;

        uint256 t0ThresholdPrice = activeBorrower ? Maths.wdiv(borrower_.t0Debt, borrower_.collateral) : 0;

        // loan not in auction, update threshold price and position in heap
        if (!inAuction_ ) {
            // get the loan id inside the heap
            uint256 loanId = loans_.indices[borrowerAddress_];
            if (activeBorrower) {
                // revert if threshold price is zero
                if (t0ThresholdPrice == 0) revert ZeroThresholdPrice();

                // update heap, insert if a new loan, update loan if already in heap
                _upsert(loans_, borrowerAddress_, loanId, uint96(t0ThresholdPrice));

            // if loan is in heap and borrwer is no longer active (no debt, no collateral) then remove loan from heap
            } else if (loanId != 0) {
                remove(loans_, borrowerAddress_, loanId);
            }
        }

        // update t0 neutral price of borrower
        if (t0NpUpdate_) {
            if (t0ThresholdPrice != 0) {
                uint256 loansInPool = loans_.loans.length - 1 + auctions_.noOfAuctions;
                uint256 curMomp     = _priceAt(Deposits.findIndexOfSum(deposits_, Maths.wdiv(poolDebt_, loansInPool * 1e18)));

                borrower_.t0Np = (1e18 + poolRate_) * curMomp * t0ThresholdPrice / lup_ / 1e18;
            } else {
                borrower_.t0Np = 0;
            }
        }

        // save borrower state
        loans_.borrowers[borrowerAddress_] = borrower_;
    }

    /**************************************/
    /***  Loans Heap Internal Functions ***/
    /**************************************/

    /**
     *  @notice Moves a `Loan` up the heap.
     *  @param loans_ Holds loans heap data.
     *  @param loan_  `Loan` to be moved.
     *  @param index_ Index of `Loan` to be moved to.
     */
    function _bubbleUp(LoansState storage loans_, Loan memory loan_, uint index_) private {
        uint256 count = loans_.loans.length;
        if (index_ == ROOT_INDEX || loan_.thresholdPrice <= loans_.loans[index_ / 2].thresholdPrice){
          _insert(loans_, loan_, index_, count);
        } else {
          _insert(loans_, loans_.loans[index_ / 2], index_, count);
          _bubbleUp(loans_, loan_, index_ / 2);
        }
    }

    /**
     *  @notice Moves a `Loan` down the heap.
     *  @param loans_ Holds loans heap data.
     *  @param loan_  `Loan` to be moved.
     *  @param index_ Index of `Loan` to be moved to.
     */
    function _bubbleDown(LoansState storage loans_, Loan memory loan_, uint index_) private {
        // Left child index.
        uint cIndex = index_ * 2;

        uint256 count = loans_.loans.length;
        if (count <= cIndex) {
            _insert(loans_, loan_, index_, count);
        } else {
            Loan memory largestChild = loans_.loans[cIndex];

            if (count > cIndex + 1 && loans_.loans[cIndex + 1].thresholdPrice > largestChild.thresholdPrice) {
                largestChild = loans_.loans[++cIndex];
            }

            if (largestChild.thresholdPrice <= loan_.thresholdPrice) {
              _insert(loans_, loan_, index_, count);
            } else {
              _insert(loans_, largestChild, index_, count);
              _bubbleDown(loans_, loan_, cIndex);
            }
        }
    }

    /**
     *  @notice Inserts a `Loan` in the heap.
     *  @param loans_ Holds loans heap data.
     *  @param loan_  `Loan` to be inserted.
     *  @param index_ Index of `Loan` to be inserted at.
     */
    function _insert(LoansState storage loans_, Loan memory loan_, uint index_, uint256 count_) private {
        if (index_ == count_) loans_.loans.push(loan_);
        else loans_.loans[index_] = loan_;

        loans_.indices[loan_.borrower] = index_;
    }

    /**
     *  @notice Removes `Loan` from heap given borrower address.
     *  @param loans_    Holds loans heap data.
     *  @param borrower_ Borrower address whose `Loan` is being updated or inserted.
     *  @param index_    Index of `Loan` to be removed.
     */
    function remove(LoansState storage loans_, address borrower_, uint256 index_) internal {
        delete loans_.indices[borrower_];
        uint256 tailIndex = loans_.loans.length - 1;
        if (index_ == tailIndex) loans_.loans.pop(); // we're removing the tail, pop without sorting
        else {
            Loan memory tail = loans_.loans[tailIndex];
            loans_.loans.pop();            // remove tail loan
            _bubbleUp(loans_, tail, index_);
            _bubbleDown(loans_, loans_.loans[index_], index_);
        }
    }

    /**
     *  @notice Performs an insert or an update dependent on borrowers existance.
     *  @param loans_          Holds loans heap data.
     *  @param borrower_       Borrower address that is being updated or inserted.
     *  @param index_          Index of `Loan` to be upserted.
     *  @param thresholdPrice_ `Threshold Price` that is updated or inserted.
     */
    function _upsert(
        LoansState storage loans_,
        address borrower_,
        uint256 index_,
        uint96 thresholdPrice_
    ) internal {
        // Loan exists, update in place.
        if (index_ != 0) {
            Loan memory currentLoan = loans_.loans[index_];
            if (currentLoan.thresholdPrice > thresholdPrice_) {
                currentLoan.thresholdPrice = thresholdPrice_;
                _bubbleDown(loans_, currentLoan, index_);
            } else {
                currentLoan.thresholdPrice = thresholdPrice_;
                _bubbleUp(loans_, currentLoan, index_);
            }

        // New loan, insert it
        } else {
            _bubbleUp(loans_, Loan(borrower_, thresholdPrice_), loans_.loans.length);
        }
    }


    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @notice Retreives `Loan` by index, `index_`.
     *  @param loans_ Holds loans heap data.
     *  @param index_ Index to retrieve `Loan`.
     *  @return `Loan` struct retrieved by index.
     */
    function getByIndex(LoansState storage loans_, uint256 index_) internal view returns(Loan memory) {
        return loans_.loans.length > index_ ? loans_.loans[index_] : Loan(address(0), 0);
    }

    /**
     *  @notice Retreives `Loan` with the highest threshold price value.
     *  @param loans_ Holds loans heap data.
     *  @return `Max Loan` in the heap.
     */
    function getMax(LoansState storage loans_) internal view returns(Loan memory) {
        return getByIndex(loans_, ROOT_INDEX);
    }

    /**
     *  @notice Returns number of loans in pool.
     *  @param loans_ Holds loans heap data.
     *  @return Number of loans in pool.
     */
    function noOfLoans(LoansState storage loans_) internal view returns (uint256) {
        return loans_.loans.length - 1;
    }
}