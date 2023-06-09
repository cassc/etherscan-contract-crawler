// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface ILoanManagerStorage {

    /**
     *  @dev    Gets the amount of accounted interest.
     *  @return accountedInterest_ The amount of accounted interest.
     */
    function accountedInterest() external view returns (uint112 accountedInterest_);

    /**
     *  @dev    Gets allowed slippage for a give collateral asset.
     *  @param  collateralAsset_ Address of a collateral asset.
     *  @return allowedSlippage_ The allowed slippage for the collateral asset.
     */
    function allowedSlippageFor(address collateralAsset_) external view returns (uint256 allowedSlippage_);

    /**
     *  @dev    Gets the timestamp of the domain end.
     *  @return domainEnd_ The timestamp of the domain end.
     */
    function domainEnd() external view returns (uint48 domainEnd_);

    /**
     *  @dev    Gets the timestamp of the domain start.
     *  @return domainStart_ The timestamp of the domain start.
     */
    function domainStart() external view returns (uint48 domainStart_);

    /**
     *  @dev    Gets the address of the funds asset.
     *  @return fundsAsset_ The address of the funds asset.
     */
    function fundsAsset() external view returns (address fundsAsset_);

    /**
     *  @dev    Gets the current issuance rate.
     *  @return issuanceRate_ The value for the issuance rate.
     */
    function issuanceRate() external view returns (uint256 issuanceRate_);

    /**
     *  @dev    Gets the information for a liquidation.
     *  @param  loan_               The address of the loan.
     *  @return triggeredByGovernor True if the liquidation was triggered by the governor.
     *  @return principal           The amount of principal to be recovered.
     *  @return interest            The amount of interest to be recovered.
     *  @return lateInterest        The amount of late interest to be recovered.
     *  @return platformFees        The amount of platform fees owed.
     *  @return liquidator          The address of the liquidator.
     */
    function liquidationInfo(address loan_) external view returns (
        bool    triggeredByGovernor,
        uint128 principal,
        uint120 interest,
        uint256 lateInterest,
        uint96  platformFees,
        address liquidator
    );

    /**
     *  @dev   Gets the minimum ratio for a collateral asset.
     *  @param collateralAsset_  Address of a collateral asset.
     *  @param minRatio_         The value for minRatio.
     */
    function minRatioFor(address collateralAsset_) external view returns (uint256 minRatio_);

    /**
     *  @dev    Gets the payment counter.
     *  @return paymentCounter_ The payment counter.
     */
    function paymentCounter() external view returns (uint24 paymentCounter_);

    /**
     *  @dev    Gets the payment if for the given loan.
     *  @param  loan_      The address of the loan.
     *  @return paymentId_ The id of the payment information.
     */
    function paymentIdOf(address loan_) external view returns (uint24 paymentId_);

    /**
     *  @dev    Gets the information for a payment.
     *  @param  paymentId_                The id of the payment information.
     *  @return platformManagementFeeRate The value for the platform management fee rate.
     *  @return delegateManagementFeeRate The value for the delegate management fee rate.
     *  @return startDate                 The start date of the payment.
     *  @return paymentDueDate            The timestamp of the payment due date.
     *  @return incomingNetInterest       The amount of incoming net interest.
     *  @return refinanceInterest         The amount of refinance interest.
     *  @return issuanceRate              The issuance rate for the loan.
     */
    function payments(uint256 paymentId_) external view returns (
        uint24  platformManagementFeeRate,
        uint24  delegateManagementFeeRate,
        uint48  startDate,
        uint48  paymentDueDate,
        uint128 incomingNetInterest,
        uint128 refinanceInterest,
        uint256 issuanceRate
    );

    /**
     *  @dev    Gets the payment id with the earliest due date.
     *  @return paymentWithEarliestDueDate_ The payment id with the earliest due date.
     */
    function paymentWithEarliestDueDate() external view returns (uint24 paymentWithEarliestDueDate_);

    /**
     *  @dev    Gets the address of the pool manager.
     *  @return poolManager_ The address of the pool manager.
     */
    function poolManager() external view returns (address poolManager_);

    /**
     *  @dev    Gets the amount of principal out.
     *  @return principalOut_ The amount of principal out.
     */
    function principalOut() external view returns (uint128 principalOut_);

    /**
     *  @dev   Gets the information of the sorted list.
     *  @param previous       The id of the item before on the list.
     *  @param next           The id of the item after on the list.
     *  @param paymentDueDate The value for the payment due date.
     */
    function sortedPayments(uint256 paymentId_) external view returns (
        uint24 previous,
        uint24 next,
        uint48 paymentDueDate
    );

    /**
     *  @dev    Returns the amount unrealized losses.
     *  @return unrealizedLosses_ Amount of unrealized losses.
     */
    function unrealizedLosses() external view returns (uint128 unrealizedLosses_);

}