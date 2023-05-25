// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./InstallmentsCalc.sol";
import "./libraries/LoanLibrary.sol";
import "./interfaces/IPromissoryNote.sol";
import "./interfaces/ILoanCore.sol";
import "./interfaces/IRepaymentController.sol";

import { RC_CannotDereference, RC_InvalidState, RC_NoPaymentDue, RC_OnlyLender, RC_BeforeStartDate, RC_NoInstallments, RC_NoMinPaymentDue, RC_RepayPartZero, RC_RepayPartLTMin, RC_HasInstallments } from "./errors/Lending.sol";

/**
 * @title RepaymentController
 * @author Non-Fungible Technologies, Inc.
 *
 * The Repayment Controller is the entry point for all loan lifecycle
 * operations in the Arcade.xyz lending protocol once a loan has begun.
 * This contract allows a caller to calculate an amount due on a loan,
 * make a payment (either in full or part, for installment loans), and
 * claim collateral on a defaulted loan. It is this contract's responsibility
 * to verify loan conditions before calling LoanCore.
 */
contract RepaymentController is IRepaymentController, InstallmentsCalc, Context {
    using SafeERC20 for IERC20;

    // ============================================ STATE ===============================================

    ILoanCore private loanCore;
    IPromissoryNote private lenderNote;

    constructor(
        ILoanCore _loanCore
    ) {
        loanCore = _loanCore;
        lenderNote = loanCore.lenderNote();
    }

    // ==================================== LIFECYCLE OPERATIONS ========================================

    /**
     * @notice Repay an active loan, referenced by borrower note ID (equivalent to loan ID). The interest for a loan
     *         is calculated, and the principal plus interest is withdrawn from the borrower.
     *         Control is passed to LoanCore to complete repayment.
     *
     * @param  loanId               The ID of the loan.
     */
    function repay(uint256 loanId) external override {
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);
        if (data.state == LoanLibrary.LoanState.DUMMY_DO_NOT_USE) revert RC_CannotDereference(loanId);
        if (data.state != LoanLibrary.LoanState.Active) revert RC_InvalidState(data.state);

        LoanLibrary.LoanTerms memory terms = data.terms;

        //cannot use for installment loans, call repayPart or repayPartMinimum
        if (terms.numInstallments != 0) revert RC_HasInstallments(terms.numInstallments);

        // withdraw principal plus interest from borrower and send to loan core
        uint256 total = getFullInterestAmount(terms.principal, terms.interestRate);
        if (total == 0) revert RC_NoPaymentDue();

        IERC20(terms.payableCurrency).safeTransferFrom(_msgSender(), address(this), total);
        IERC20(terms.payableCurrency).approve(address(loanCore), total);

        // call repay function in loan core
        loanCore.repay(loanId);
    }

    /**
     * @notice Claim collateral on an active loan, referenced by lender note ID (equivalent to loan ID).
     *        The loan must be past the due date, or, in the case of an installment, the amount
     *         overdue must be beyond the liquidation threshold. No funds are collected
     *         from the borrower.
     *
     * @param  loanId               The ID of the loan.
     */
    function claim(uint256 loanId) external override {
        // make sure that caller owns lender note
        // Implicitly checks if loan is active - if inactive, note will not exist
        address lender = lenderNote.ownerOf(loanId);
        if (lender != msg.sender) revert RC_OnlyLender(msg.sender);
        // get LoanData to check the current installment period, then send this value as a parameter to LoanCore.
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);
        if (data.terms.numInstallments > 0) {
            // get the current installment period
            uint256 _installmentPeriod = currentInstallmentPeriod(
                data.startDate,
                data.terms.durationSecs,
                data.terms.numInstallments
            );
            // call claim function in loan core
            loanCore.claim(loanId, _installmentPeriod);
        } else {
            // call claim function in loan core indicating a legacy loan type with 0 as the installment period
            // installment loans cannot have an installment period of 0
            loanCore.claim(loanId, 0);
        }
    }

    // =========================== INSTALLMENT SPECIFIC OPERATIONS ===============================

    /**
     * @notice Call _calcAmountsDue publicly to determine the amount of the payable currency
     *         must be approved for the payment. Returns minimum balance due, late fees, and number
     *         of missed payments.
     *
     * @dev Calls _calcAmountsDue similar to repayPart and repayPartMinimum, but does not call LoanCore.
     *
     * @param loanId                            LoanId, used to locate terms.
     *
     * @return minInterestDue                   The amount of interest due, compounded over missed payments.
     * @return lateFees                         The amount of late fees due, compounded over missed payments.
     * @return _installmentsMissed              The number of overdue installment periods since the last payment.
     */
    function getInstallmentMinPayment(uint256 loanId)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // loan terms from loanId
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);
        // get loan from borrower note
        if (data.state == LoanLibrary.LoanState.DUMMY_DO_NOT_USE) revert RC_CannotDereference(loanId);
        if (data.state != LoanLibrary.LoanState.Active) revert RC_InvalidState(data.state);

        uint256 installments = data.terms.numInstallments;
        if (installments == 0) revert RC_NoInstallments(installments);

        // get the current minimum balance due for the installment
        (uint256 minInterestDue, uint256 lateFees, uint256 numMissedPayments) = _calcAmountsDue(
            data.balance,
            data.startDate,
            data.terms.durationSecs,
            installments,
            data.numInstallmentsPaid,
            data.terms.interestRate
        );

        return (minInterestDue, lateFees, numMissedPayments);
    }

    /**
     * @notice Called when paying back installment loan with the minimum amount due.
     *         Do not call for single payment loan types. Calling this function does not
     *         reduce the loans principal.
     *
     * @dev Only pay off the current interest amount and, if applicable, any late fees accrued.
     *
     * @param loanId                            LoanId, used to locate terms.
     */
    function repayPartMinimum(uint256 loanId) external override {
        // get current minimum balance due for the installment repayment, based on specific loanId.
        (uint256 minBalanceDue, uint256 lateFees, uint256 numMissedPayments) = getInstallmentMinPayment(loanId);
        // total amount due equals interest amount plus any late fees
        uint256 _minAmount = minBalanceDue + lateFees;
        // cannot call repayPartMinimum twice in the same installment period
        if (_minAmount == 0) revert RC_NoPaymentDue();

        // load terms from loanId
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);
        // gather minimum payment from _msgSender()
        IERC20(data.terms.payableCurrency).safeTransferFrom(_msgSender(), address(this), _minAmount);
        // approve loanCore to take minBalanceDue
        IERC20(data.terms.payableCurrency).approve(address(loanCore), _minAmount);
        // call repayPart function in loanCore
        loanCore.repayPart(loanId, numMissedPayments, 0, minBalanceDue, lateFees);
    }

    /**
     * @notice Called when paying back installment loan with an amount greater than the minimum amount due.
     *         Do not call for single payment loan types. If one wishes to repay the minimum, use
     *         repayPartMinimum.
     *
     * @dev Pay off the current interest and, if applicable any late fees accrued, and an additional
     *      amount to be deducted from the loan principal.
     *
     * @param loanId                            LoanId, used to locate terms.
     * @param amount                            Amount = minBalDue + lateFees + amountToPayOffPrincipal
     *                                          value must be greater than minBalDue + latefees returned
     *                                          from getInstallmentMinPayment function call.
     */
    function repayPart(uint256 loanId, uint256 amount) external override {
        if (amount == 0) revert RC_RepayPartZero();

        // get current minimum balance due for the installment repayment, based on specific loanId.
        (uint256 minBalanceDue, uint256 lateFees, uint256 numMissedPayments) = getInstallmentMinPayment(loanId);
        // total minimum amount due, interest amount plus any late fees
        uint256 _minAmount = minBalanceDue + lateFees;
        // require amount taken from the _msgSender() to be larger than or equal to minBalanceDue
        if (amount < _minAmount) revert RC_RepayPartLTMin(amount, _minAmount);
        // loan data from loanId
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);
        // calculate the payment toward principal after subtracting (minBalanceDue + lateFees)
        uint256 _totalPaymentToPrincipal = amount - (_minAmount);
        // collect amount specified in function call params from _msgSender()
        IERC20(data.terms.payableCurrency).safeTransferFrom(_msgSender(), address(this), amount);
        // approve loanCore to take amount
        IERC20(data.terms.payableCurrency).approve(address(loanCore), amount);
        // call repayPart function in loanCore
        loanCore.repayPart(loanId, numMissedPayments, _totalPaymentToPrincipal, minBalanceDue, lateFees);
    }

    /**
     * @notice Called when the user wants to close an installment loan without needing to determine the
     *         amount to pass to the repayPart function. This is done by paying the remaining principal
     *         and any interest or late fees due.
     *
     * @dev Pay off the current interest and, if applicable any late fees accrued, and the remaining principal
     *      left on the loan.
     *
     * @param loanId                            LoanId, used to locate terms.
     */
    function closeLoan(uint256 loanId) external override {
        // get current minimum balance due for the installment repayment, based on specific loanId.
        (uint256 minBalanceDue, uint256 lateFees, uint256 numMissedPayments) = getInstallmentMinPayment(loanId);
        // loan data from loanId
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);
        // total amount to close loan (remaining balance + current interest + late fees)
        uint256 _totalAmount = data.balance + minBalanceDue + lateFees;
        // collect amount specified in function call params from _msgSender()
        IERC20(data.terms.payableCurrency).safeTransferFrom(_msgSender(), address(this), _totalAmount);
        // approve loanCore to take minBalanceDue
        IERC20(data.terms.payableCurrency).approve(address(loanCore), _totalAmount);
        // Call repayPart function in loanCore.
        loanCore.repayPart(loanId, numMissedPayments, data.balance, minBalanceDue, lateFees);
    }

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @notice Called when the user wants to determine the remaining balance for closing the loan.
     *
     * @dev View the current interest and, if applicable any late fees accrued, in addition to any
     *      remaining principal left on the loan.
     *
     * @param loanId                            LoanId, used to locate terms.
     *
     * @return amountDue                        The total amount due to close the loan, including principal, interest,
     *                                          and late fees.
     * @return numMissedPayments                The number of missed payments.
     */
    function amountToCloseLoan(uint256 loanId) external view override returns (uint256, uint256) {
        // get current minimum balance due for the installment repayment, based on specific loanId.
        (uint256 minBalanceDue, uint256 lateFees, uint256 numMissedPayments) = getInstallmentMinPayment(loanId);
        // loan data from loanId
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);

        // the required total amount needed to close the loan (remaining balance + current interest + late fees)
        return ((data.balance + minBalanceDue + lateFees), numMissedPayments);
    }
}