// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxied } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";

import { ILoanManagerStorage } from "./ILoanManagerStorage.sol";

interface ILoanManager is IMapleProxied, ILoanManagerStorage {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Emitted when the accounting state of the loan manager is updated.
     *  @param issuanceRate_      New value for the issuance rate.
     *  @param accountedInterest_ The amount of accounted interest.
     */
    event AccountingStateUpdated(uint256 issuanceRate_, uint112 accountedInterest_);

    /**
     *  @dev   Funds have been claimed and distributed to the Pool, Pool Delegate, and Maple Treasury.
     *  @param loan_                  The address of the loan contract.
     *  @param principal_             The amount of principal paid.
     *  @param netInterest_           The amount of net interest paid.
     *  @param delegateManagementFee_ The amount of delegate management fees paid.
     *  @param delegateServiceFee_    The amount of delegate service fees paid.
     *  @param platformManagementFee_ The amount of platform management fees paid.
     *  @param platformServiceFee_    The amount of platform service fees paid.
     */
    event ClaimedFundsDistributed(
        address indexed loan_,
        uint256 principal_,
        uint256 netInterest_,
        uint256 delegateManagementFee_,
        uint256 delegateServiceFee_,
        uint256 platformManagementFee_,
        uint256 platformServiceFee_
    );

    /**
     *  @dev   Funds that were expected to be claimed and distributed to the Pool and Maple Treasury.
     *  @param loan_                  The address of the loan contract.
     *  @param principal_             The amount of principal that was expected to be paid.
     *  @param netInterest_           The amount of net interest that was expected to be paid.
     *  @param platformManagementFee_ The amount of platform management fees that were expected to be paid.
     *  @param platformServiceFee_    The amount of platform service fees that were expected to paid.
     */
    event ExpectedClaim(
        address indexed loan_,
        uint256 principal_,
        uint256 netInterest_,
        uint256 platformManagementFee_,
        uint256 platformServiceFee_
    );

    /**
     *  @dev   Funds that were liquidated and distributed to the Pool, Maple Treasury, and Borrower.
     *  @param loan_       The address of the loan contract that defaulted and was liquidated.
     *  @param toBorrower_ The amount of recovered funds transferred to the Borrower.
     *  @param toPool_     The amount of recovered funds transferred to the Pool.
     *  @param toTreasury_ The amount of recovered funds transferred to the Treasury.
     */
    event LiquidatedFundsDistributed(address indexed loan_, uint256 toBorrower_, uint256 toPool_, uint256 toTreasury_);

    /**
     *  @dev   Emitted when a payment is added to the LoanManager payments mapping.
     *  @param loan_                      The address of the loan.
     *  @param platformManagementFeeRate_ The amount of platform management rate that will be used for the payment distribution.
     *  @param delegateManagementFeeRate_ The amount of delegate management rate that will be used for the payment distribution.
     *  @param paymentDueDate_            The due date of the payment.
     *  @param issuanceRate_              The issuance of the payment, 1e27 precision.
     */
    event PaymentAdded(
        address indexed loan_,
        uint256 platformManagementFeeRate_,
        uint256 delegateManagementFeeRate_,
        uint256 paymentDueDate_,
        uint256 issuanceRate_
    );

    /**
     *  @dev   Emitted when a payment is removed from the LoanManager payments mapping.
     *  @param loan_ The address of the loan.
     */
    event PaymentRemoved(address indexed loan_);

    /**
     *  @dev   Emitted when principal out is updated
     *  @param principalOut_ The new value for principal out.
     */
    event PrincipalOutUpdated(uint128 principalOut_);

    /**
     *  @dev   Emitted when unrealized losses is updated.
     *  @param unrealizedLosses_ The new value for unrealized losses.
     */
    event UnrealizedLossesUpdated(uint128 unrealizedLosses_);

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // NOTE: setPendingLender and acceptPendingLender were not implemented in the LoanManager even though they exist on the Loan
    //       contract. This is because the Loan will support this functionality always, but it was not deemed necessary for the
    //       LoanManager to support this functionality.

    /**
     *  @dev   Calls a loan.
     *  @param loan_      Loan to be called.
     *  @param principal_ Amount of principal to call the Loan with.
     */
    function callPrincipal(address loan_, uint256 principal_) external;

    /**
     *  @dev   Called by loans when payments are made, updating the accounting.
     *  @param principal_          The difference in principal. Positive if net principal change moves funds into pool, negative if it moves
     *                             funds out of pool.
     *  @param interest_           The amount of interest paid.
     *  @param platformServiceFee_ The amount of platform service fee paid.
     *  @param delegateServiceFee_ The amount of delegate service fee paid.
     *  @param paymentDueDate_     The new payment due date.
     */
    function claim(
        int256  principal_,
        uint256 interest_,
        uint256 delegateServiceFee_,
        uint256 platformServiceFee_,
        uint40  paymentDueDate_
    ) external;

    /**
     *  @dev   Funds a new loan.
     *  @param loan_ Loan to be funded.
     */
    function fund(address loan_) external;

    /**
     *  @dev   Triggers the impairment of a loan.
     *  @param loan_ Loan to trigger the loan impairment.
     */
    function impairLoan(address loan_) external;

    /**
     *  @dev   Proposes new terms for a loan.
     *  @param loan_       The loan to propose new changes to.
     *  @param refinancer_ The refinancer to use in the refinance.
     *  @param deadline_   The deadline by which the borrower must accept the new terms.
     *  @param calls_      The array of calls to be made to the refinancer.
     */
    function proposeNewTerms(address loan_, address refinancer_, uint256 deadline_, bytes[] calldata calls_) external;

    /**
     *  @dev   Reject/cancel proposed new terms for a loan.
     *  @param loan_       The loan with the proposed new changes.
     *  @param refinancer_ The refinancer to use in the refinance.
     *  @param deadline_   The deadline by which the borrower must accept the new terms.
     *  @param calls_      The array of calls to be made to the refinancer.
     */
    function rejectNewTerms(address loan_, address refinancer_, uint256 deadline_, bytes[] calldata calls_) external;

    /**
     *  @dev   Removes a loan call.
     *  @param loan_ Loan to remove call for.
     */
    function removeCall(address loan_) external;

    /**
     *  @dev   Removes the loan impairment for a loan.
     *  @param loan_ Loan to remove the loan impairment.
     */
    function removeLoanImpairment(address loan_) external;

    /**
     *  @dev    Triggers the default of a loan. Different interface for PM to accommodate vs FT-LM.
     *  @param  loan_                    Loan to trigger the default.
     *  @param  liquidatorFactory_       Address of the liquidator factory (ignored for open-term loans).
     *  @return liquidationComplete_     If the liquidation is complete (always true for open-term loans)
     *  @return remainingLosses_         The amount of un-recovered principal and interest (net of management fees).
     *  @return unrecoveredPlatformFees_ The amount of un-recovered platform fees.
     */
    function triggerDefault(
        address loan_,
        address liquidatorFactory_
    ) external returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 unrecoveredPlatformFees_);

    /**
     *  @dev    Triggers the default of a loan.
     *  @param  loan_                    Loan to trigger the default.
     *  @return remainingLosses_         The amount of un-recovered principal and interest (net of management fees).
     *  @return unrecoveredPlatformFees_ The amount of un-recovered platform fees.
     */
    function triggerDefault(address loan_) external returns (uint256 remainingLosses_, uint256 unrecoveredPlatformFees_);

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the value considered as the hundred percent.
     *  @return hundredPercent_ The value considered as the hundred percent.
     */
    function HUNDRED_PERCENT() external returns (uint256 hundredPercent_);

    /**
     *  @dev    Returns the precision used for the contract.
     *  @return precision_ The precision used for the contract.
     */
    function PRECISION() external returns (uint256 precision_);

    /**
     *  @dev    Gets the amount of accrued interest up until this point in time.
     *  @return accruedInterest_ The amount of accrued interest up until this point in time.
     */
    function accruedInterest() external view returns (uint256 accruedInterest_);

    /**
     *  @dev    Gets the amount of assets under the management of the contract.
     *  @return assetsUnderManagement_ The amount of assets under the management of the contract.
     */
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);

}