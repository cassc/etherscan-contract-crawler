// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxied } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";

import { IMapleLoanEvents }  from "./IMapleLoanEvents.sol";
import { IMapleLoanStorage } from "./IMapleLoanStorage.sol";

/// @title MapleLoan implements an open term loan, and is intended to be proxied.
interface IMapleLoan is IMapleProxied, IMapleLoanEvents, IMapleLoanStorage {

    /**************************************************************************************************************************************/
    /*** State Changing Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev Accept the borrower role, must be called by pendingBorrower.
     */
    function acceptBorrower() external;

    /**
     *  @dev Accept the lender role, must be called by pendingLender.
     */
    function acceptLender() external;

    /**
     *  @dev    Accept the proposed terms and trigger refinance execution.
     *  @param  refinancer_          The address of the refinancer contract.
     *  @param  deadline_            The deadline for accepting the new terms.
     *  @param  calls_               The encoded arguments to be passed to refinancer.
     *  @return refinanceCommitment_ The hash of the accepted refinance agreement.
     */
    function acceptNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external returns (bytes32 refinanceCommitment_);

    /**
     *  @dev    The lender called the loan, giving the borrower a notice period within which to return principal and pro-rata interest.
     *  @param  principalToReturn_ The minimum amount of principal the borrower must return.
     *  @return paymentDueDate_    The new payment due date for returning the principal and pro-rate interest to the lender.
     *  @return defaultDate_       The date the loan will be in default.
     */
    function callPrincipal(uint256 principalToReturn_) external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev    Lend funds to the loan/borrower.
     *  @return fundsLent_      The amount funded.
     *  @return paymentDueDate_ The due date of the first payment.
     *  @return defaultDate_    The timestamp of the date the loan will be in default.
     */
    function fund() external returns (uint256 fundsLent_, uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev    Fast forward the payment due date to the current time.
     *          This enables the pool delegate to force a payment (or default).
     *  @return paymentDueDate_ The new payment due date to result in the removal of the loan's impairment status.
     *  @return defaultDate_    The timestamp of the date the loan will be in default.
     */
    function impair() external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev    Make a payment to the loan.
     *  @param  principalToReturn_  The amount of principal to return, to the lender to reduce future interest payments.
     *  @return interest_           The portion of the amount paying interest.
     *  @return lateInterest_       The portion of the amount paying late interest.
     *  @return delegateServiceFee_ The portion of the amount paying delegate service fees.
     *  @return platformServiceFee_ The portion of the amount paying platform service fees.
     */
    function makePayment(uint256 principalToReturn_)
        external returns (
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        );

    /**
     *  @dev    Propose new terms for refinance.
     *  @param  refinancer_          The address of the refinancer contract.
     *  @param  deadline_            The deadline for accepting the new terms.
     *  @param  calls_               The encoded arguments to be passed to refinancer.
     *  @return refinanceCommitment_ The hash of the proposed refinance agreement.
     */
    function proposeNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external returns (bytes32 refinanceCommitment_);

    /**
     *  @dev    Nullify the current proposed terms.
     *  @param  refinancer_          The address of the refinancer contract.
     *  @param  deadline_            The deadline for accepting the new terms.
     *  @param  calls_               The encoded arguments to be passed to refinancer.
     *  @return refinanceCommitment_ The hash of the rejected refinance agreement.
     */
    function rejectNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external returns (bytes32 refinanceCommitment_);

    /**
     *  @dev    Remove the loan's called status.
     *  @return paymentDueDate_ The restored payment due date.
     *  @return defaultDate_    The date the loan will be in default.
     */
    function removeCall() external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev    Remove the loan impairment by restoring the original payment due date.
     *  @return paymentDueDate_ The restored payment due date.
     *  @return defaultDate_    The timestamp of the date the loan will be in default.
     */
    function removeImpairment() external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev    Repossess collateral, and any funds, for a loan in default.
     *  @param  destination_      The address where the collateral and funds asset is to be sent, if any.
     *  @return fundsRepossessed_ The amount of funds asset repossessed.
     */
    function repossess(address destination_) external returns (uint256 fundsRepossessed_);

    /**
     *  @dev   Set the `pendingBorrower` to a new account.
     *  @param pendingBorrower_ The address of the new pendingBorrower.
     */
    function setPendingBorrower(address pendingBorrower_) external;

    /**
     *  @dev   Set the `pendingLender` to a new account.
     *  @param pendingLender_ The address of the new pendingLender.
     */
    function setPendingLender(address pendingLender_) external;

    /**
     *  @dev    Remove all available balance of a specified token.
     *          NOTE: Open Term Loans are not designed to hold custody of tokens, so this is designed as a safety feature.
     *  @param  token_       The address of the token contract.
     *  @param  destination_ The recipient of the token.
     *  @return skimmed_     The amount of token removed from the loan.
     */
    function skim(address token_, address destination_) external returns (uint256 skimmed_);

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev The timestamp of the date the loan will be in default.
     */
    function defaultDate() external view returns (uint40 defaultDate_);

    /**
     *  @dev The Maple globals address
     */
    function globals() external view returns (address globals_);

    /**
     *  @dev The value that represents 100%, to be easily comparable with the loan rates.
     */
    function HUNDRED_PERCENT() external pure returns (uint256 hundredPercent_);

    /**
     *  @dev Whether the loan is called.
     */
    function isCalled() external view returns (bool isCalled_);

    /**
     *  @dev Whether the loan is impaired.
     */
    function isImpaired() external view returns (bool isImpaired_);

    /**
     *  @dev Whether the loan is in default.
     */
    function isInDefault() external view returns (bool isInDefault_);

    /**
     *  @dev    Get the breakdown of the total payment needed to satisfy the next payment installment.
     *  @param  timestamp_          The timestamp that corresponds to when the payment is to be made.
     *  @return principal_          The portion of the total amount that will go towards principal.
     *  @return interest_           The portion of the total amount that will go towards interest fees.
     *  @return lateInterest_       The portion of the total amount that will go towards late interest fees.
     *  @return delegateServiceFee_ The portion of the total amount that will go towards delegate service fees.
     *  @return platformServiceFee_ The portion of the total amount that will go towards platform service fees.
     */
    function getPaymentBreakdown(uint256 timestamp_)
        external view returns (
            uint256 principal_,
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        );

    /**
     *  @dev The timestamp of the due date of the next payment.
     */
    function paymentDueDate() external view returns (uint40 paymentDueDate_);

}