// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxied } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";

import { ILoanManagerStorage } from "./ILoanManagerStorage.sol";

interface ILoanManager is IMapleProxied, ILoanManagerStorage {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Emitted when `setAllowedSlippage` is called.
     *  @param collateralAsset_ Address of a collateral asset.
     *  @param newSlippage_     New value for `allowedSlippage`.
     */
    event AllowedSlippageSet(address collateralAsset_, uint256 newSlippage_);

    /**
     *  @dev   Funds have been claimed and distributed into the Pool.
     *  @param loan_        The address of the loan contract.
     *  @param principal_   The amount of principal paid.
     *  @param netInterest_ The amount of net interest paid.
     */
    event FundsDistributed(address indexed loan_, uint256 principal_, uint256 netInterest_);

    /**
     *  @dev   Emitted when the issuance parameters are changed.
     *  @param domainEnd_         The timestamp of the domain end.
     *  @param issuanceRate_      New value for the issuance rate.
     *  @param accountedInterest_ The amount of accounted interest.
     */
    event IssuanceParamsUpdated(uint48 domainEnd_, uint256 issuanceRate_, uint112 accountedInterest_);

    /**
     *  @dev   Emitted when the loanTransferAdmin is set by the PoolDelegate.
     *  @param loanTransferAdmin_ The address of the admin that can transfer loans.
     */
    event LoanTransferAdminSet(address indexed loanTransferAdmin_);

    /**
     *  @dev   A fee payment was made.
     *  @param loan_                  The address of the loan contract.
     *  @param delegateManagementFee_ The amount of delegate management fee paid.
     *  @param platformManagementFee_ The amount of platform management fee paid.
     */
    event ManagementFeesPaid(address indexed loan_, uint256 delegateManagementFee_, uint256 platformManagementFee_);

    /**
     *  @dev   Emitted when `setMinRatio` is called.
     *  @param collateralAsset_ Address of a collateral asset.
     *  @param newMinRatio_     New value for `minRatio`.
     */
    event MinRatioSet(address collateralAsset_, uint256 newMinRatio_);

    /**
     *  @dev   Emitted when a payment is removed from the LoanManager payments array.
     *  @param loan_      The address of the loan.
     *  @param paymentId_ The payment ID of the payment that was removed.
     */
    event PaymentAdded(
        address indexed loan_,
        uint256 indexed paymentId_,
        uint256         platformManagementFeeRate_,
        uint256         delegateManagementFeeRate_,
        uint256         startDate_,
        uint256         nextPaymentDueDate_,
        uint256         netRefinanceInterest_,
        uint256         newRate_
    );

    /**
     *  @dev   Emitted when a payment is removed from the LoanManager payments array.
     *  @param loan_      The address of the loan.
     *  @param paymentId_ The payment ID of the payment that was removed.
     */
    event PaymentRemoved(address indexed loan_, uint256 indexed paymentId_);

    /**
     *  @dev   Emitted when principal out is updated
     *  @param principalOut_ The new value for principal out.
     */
    event PrincipalOutUpdated(uint128 principalOut_);

    /**
     *  @dev   Emitted when unrealized losses is updated.
     *  @param unrealizedLosses_ The new value for unrealized losses.
     */
    event UnrealizedLossesUpdated(uint256 unrealizedLosses_);

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // NOTE: setPendingLender and acceptPendingLender were not implemented in the LoanManager even though they exist on the Loan
    //       contract. This is because the Loan will support this functionality always, but it was not deemed necessary for the
    //       LoanManager to support this functionality.

    /**
     *  @dev   Accepts new loan terms triggering a loan refinance.
     *  @param loan_              Loan to be refinanced.
     *  @param refinancer_        The address of the refinancer.
     *  @param deadline_          The new deadline to execute the refinance.
     *  @param calls_             The encoded calls to set new loan terms.
     *  @param principalIncrease_ The increase in principal.
     */
    function acceptNewTerms(
        address          loan_,
        address          refinancer_,
        uint256          deadline_,
        bytes[] calldata calls_,
        uint256          principalIncrease_
    ) external;

    /**
     *  @dev   Called by loans when payments are made, updating the accounting.
     *  @param principal_              The amount of principal paid.
     *  @param interest_               The amount of interest paid.
     *  @param previousPaymentDueDate_ The previous payment due date.
     *  @param nextPaymentDueDate_     The new payment due date.
     */
    function claim(uint256 principal_, uint256 interest_, uint256 previousPaymentDueDate_, uint256 nextPaymentDueDate_) external;

    /**
     *  @dev    Finishes the collateral liquidation.
     *  @param  loan_            Loan that had its collateral liquidated.
     *  @return remainingLosses_ The amount of remaining losses.
     *  @return platformFees_    The amount of platform fees.
     */
    function finishCollateralLiquidation(address loan_) external returns (uint256 remainingLosses_, uint256 platformFees_);

    /**
     *  @dev   Funds a new loan.
     *  @param loan_ Loan to be funded.
     */
    function fund(address loan_) external;

    /**
     *  @dev   Triggers the loan impairment for a loan.
     *  @param loan_ Loan to trigger the loan impairment.
     */
    function impairLoan(address loan_) external;

    /**
     *  @dev   Removes the loan impairment for a loan.
     *  @param loan_ Loan to remove the loan impairment.
     */
    function removeLoanImpairment(address loan_) external;

    /**
     *  @dev   Reject/cancel proposed new terms for a loan.
     *  @param loan_       The loan with the proposed new changes.
     *  @param refinancer_ The refinancer to use in the refinance.
     *  @param deadline_   The deadline by which the lender must accept the new terms.
     *  @param calls_      The array of calls to be made to the refinancer.
     */
    function rejectNewTerms(address loan_, address refinancer_, uint256 deadline_, bytes[] calldata calls_) external;

    /**
     *  @dev   Sets the allowed slippage for a collateral asset liquidation.
     *  @param collateralAsset_  Address of a collateral asset.
     *  @param allowedSlippage_  New value for `allowedSlippage`.
     */
    function setAllowedSlippage(address collateralAsset_, uint256 allowedSlippage_) external;

    /**
     *  @dev   Sets the minimum ratio for a collateral asset liquidation.
     *         This ratio is expressed as a decimal representation of units of fundsAsset
     *         per unit collateralAsset in fundsAsset decimal precision.
     *  @param collateralAsset_  Address of a collateral asset.
     *  @param minRatio_         New value for `minRatio`.
     */
    function setMinRatio(address collateralAsset_, uint256 minRatio_) external;

    /**
     *  @dev    Triggers the default of a loan.
     *  @param  loan_                Loan to trigger the default.
     *  @param  liquidatorFactory_   Factory that will be used to deploy the liquidator.
     *  @return liquidationComplete_ True if the liquidation is completed in the same transaction (uncollateralized).
     *  @return remainingLosses_     The amount of remaining losses.
     *  @return platformFees_        The amount of platform fees.
     */
    function triggerDefault(address loan_, address liquidatorFactory_)
        external returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 platformFees_);

    /**
     *  @dev Updates the issuance parameters of the LoanManager, callable by the Governor and the PoolDelegate.
     *       Useful to call when `block.timestamp` is greater than `domainEnd` and the LoanManager is not accruing interest.
     */
    function updateAccounting() external;

    /**************************************************************************************************************************************/
    /*** Pure/View Functions                                                                                                            ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the value considered as the hundred percent.
     *  @return hundredPercent_ The value considered as the hundred percent.
     */
    function HUNDRED_PERCENT() external pure returns (uint256 hundredPercent_);

    /**
     *  @dev    Returns the precision used for the contract.
     *  @return precision_ The precision used for the contract.
     */
    function PRECISION() external pure returns (uint256 precision_);

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

    /**
     *  @dev    Gets the expected amount of an asset given the input amount.
     *  @param  collateralAsset_ The collateral asset that is being liquidated.
     *  @param  swapAmount_      The swap amount of collateral asset.
     *  @return returnAmount_    The desired return amount of funds asset.
     */
    function getExpectedAmount(address collateralAsset_, uint256 swapAmount_) external view returns (uint256 returnAmount_);

    /**
     *  @dev    Returns whether or not a liquidation is in progress.
     *  @param  loan_     The address of the loan contract.
     *  @return isActive_ True if a liquidation is in progress.
     */
    function isLiquidationActive(address loan_) external view returns (bool isActive_);

}