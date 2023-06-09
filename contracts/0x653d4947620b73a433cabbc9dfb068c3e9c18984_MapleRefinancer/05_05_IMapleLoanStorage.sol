// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

/// @title MapleLoanStorage define the storage slots for MapleLoan, which is intended to be proxied.
interface IMapleLoanStorage {

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev The borrower of the loan, responsible for repayments.
     */
    function borrower() external view returns (address borrower_);

    /**
     *  @dev The amount of principal yet to be returned to satisfy the loan call.
     */
    function calledPrincipal() external view returns (uint256 calledPrincipal_);

    /**
     *  @dev The timestamp of the date the loan was called.
     */
    function dateCalled() external view returns (uint40 dateCalled_);

    /**
     *  @dev The timestamp of the date the loan was funded.
     */
    function dateFunded() external view returns (uint40 dateFunded_);

    /**
     *  @dev The timestamp of the date the loan was impaired.
     */
    function dateImpaired() external view returns (uint40 dateImpaired_);

    /**
     *  @dev The timestamp of the date the loan was last paid.
     */
    function datePaid() external view returns (uint40 datePaid_);

    /**
     *  @dev The annualized delegate service fee rate.
     */
    function delegateServiceFeeRate() external view returns (uint64 delegateServiceFeeRate_);

    /**
     *  @dev The address of the fundsAsset funding the loan.
     */
    function fundsAsset() external view returns (address asset_);

    /**
     *  @dev The amount of time the borrower has, after a payment is due, to make a payment before being in default.
     */
    function gracePeriod() external view returns (uint32 gracePeriod_);

    /**
     *  @dev The annualized interest rate (APR), in units of 1e18, (i.e. 1% is 0.01e18).
     */
    function interestRate() external view returns (uint64 interestRate_);

    /**
     *  @dev The rate charged at late payments.
     */
    function lateFeeRate() external view returns (uint64 lateFeeRate_);

    /**
     *  @dev The premium over the regular interest rate applied when paying late.
     */
    function lateInterestPremiumRate() external view returns (uint64 lateInterestPremiumRate_);

    /**
     *  @dev The lender of the Loan.
     */
    function lender() external view returns (address lender_);

    /**
     *  @dev The amount of time the borrower has, after the loan is called, to make a payment, paying back the called principal.
     */
    function noticePeriod() external view returns (uint32 noticePeriod_);

    /**
     *  @dev The specified time between loan payments.
     */
    function paymentInterval() external view returns (uint32 paymentInterval_);

    /**
     *  @dev The address of the pending borrower.
     */
    function pendingBorrower() external view returns (address pendingBorrower_);

    /**
     *  @dev The address of the pending lender.
     */
    function pendingLender() external view returns (address pendingLender_);

    /**
     *  @dev The annualized platform service fee rate.
     */
    function platformServiceFeeRate() external view returns (uint64 platformServiceFeeRate_);

    /**
     *  @dev The amount of principal owed (initially, the requested amount), which needs to be paid back.
     */
    function principal() external view returns (uint256 principal_);

    /**
     *  @dev The hash of the proposed refinance agreement.
     */
    function refinanceCommitment() external view returns (bytes32 refinanceCommitment_);

}