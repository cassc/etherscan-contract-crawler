// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IMapleLoanFeeManager {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   New fee terms have been set.
     *  @param loan_                   The address of the loan contract.
     *  @param delegateOriginationFee_ The new value for delegate origination fee.
     *  @param delegateServiceFee_     The new value for delegate service fee.
     */
    event FeeTermsUpdated(address loan_, uint256 delegateOriginationFee_, uint256 delegateServiceFee_);

    /**
     *  @dev   A fee payment was made.
     *  @param loan_                   The address of the loan contract.
     *  @param delegateOriginationFee_ The amount of delegate origination fee paid.
     *  @param platformOriginationFee_ The amount of platform origination fee paid.
    */
    event OriginationFeesPaid(address loan_, uint256 delegateOriginationFee_, uint256 platformOriginationFee_);

    /**
     *  @dev   New fee terms have been set.
     *  @param loan_                      The address of the loan contract.
     *  @param partialPlatformServiceFee_ The  value for the platform service fee.
     *  @param partialDelegateServiceFee_ The  value for the delegate service fee.
     */
    event PartialRefinanceServiceFeesUpdated(address loan_, uint256 partialPlatformServiceFee_, uint256 partialDelegateServiceFee_);

    /**
     *  @dev   New fee terms have been set.
     *  @param loan_               The address of the loan contract.
     *  @param platformServiceFee_ The new value for the platform service fee.
     */
    event PlatformServiceFeeUpdated(address loan_, uint256 platformServiceFee_);

    /**
     *  @dev   A fee payment was made.
     *  @param loan_                               The address of the loan contract.
     *  @param delegateServiceFee_                 The amount of delegate service fee paid.
     *  @param partialRefinanceDelegateServiceFee_ The amount of partial delegate service fee from refinance paid.
     *  @param platformServiceFee_                 The amount of platform service fee paid.
     *  @param partialRefinancePlatformServiceFee_ The amount of partial platform service fee from refinance paid.
     */
    event ServiceFeesPaid(
        address loan_,
        uint256 delegateServiceFee_,
        uint256 partialRefinanceDelegateServiceFee_,
        uint256 platformServiceFee_,
        uint256 partialRefinancePlatformServiceFee_
    );

    /**************************************************************************************************************************************/
    /*** Payment Functions                                                                                                              ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Called during `makePayment`, performs fee payments to the pool delegate and treasury.
     *  @param asset_            The address asset in which fees were paid.
     *  @param numberOfPayments_ The number of payments for which service fees will be paid.
     */
    function payServiceFees(address asset_, uint256 numberOfPayments_) external returns (uint256 feePaid_);

    /**
     *  @dev    Called during `fundLoan`, performs fee payments to poolDelegate and treasury.
     *  @param  asset_              The address asset in which fees were paid.
     *  @param  principalRequested_ The total amount of principal requested, which will be used to calculate fees.
     *  @return feePaid_            The total amount of fees paid.
     */
    function payOriginationFees(address asset_, uint256 principalRequested_) external returns (uint256 feePaid_);

    /**************************************************************************************************************************************/
    /*** Fee Update Functions                                                                                                           ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Called during loan creation or refinance, sets the fee terms.
     *  @param delegateOriginationFee_ The amount of delegate origination fee to be paid.
     *  @param delegateServiceFee_     The amount of delegate service fee to be paid.
     */
    function updateDelegateFeeTerms(uint256 delegateOriginationFee_, uint256 delegateServiceFee_) external;

    /**
     *  @dev Function called by loans to update the saved platform service fee rate.
     */
    function updatePlatformServiceFee(uint256 principalRequested_, uint256 paymentInterval_) external;

    /**
     *  @dev   Called during loan refinance to save the partial service fees accrued.
     *  @param principalRequested_   The amount of principal pre-refinance requested.
     *  @param timeSinceLastDueDate_ The amount of time since last payment due date.
     */
    function updateRefinanceServiceFees(uint256 principalRequested_, uint256 timeSinceLastDueDate_) external;

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Gets the delegate origination fee for the given loan.
     *  @param  loan_                   The address of the loan contract.
     *  @return delegateOriginationFee_ The amount of origination to be paid to delegate.
     */
    function delegateOriginationFee(address loan_) external view returns (uint256 delegateOriginationFee_);

    /**
     *  @dev    Gets the delegate service fee rate for the given loan.
     *  @param  loan_                        The address of the loan contract.
     *  @return delegateRefinanceServiceFee_ The amount of delegate service fee to be paid.
     */
    function delegateRefinanceServiceFee(address loan_) external view returns (uint256 delegateRefinanceServiceFee_);

    /**
     *  @dev    Gets the delegate service fee rate for the given loan.
     *  @param  loan_               The address of the loan contract.
     *  @return delegateServiceFee_ The amount of delegate service fee to be paid.
     */
    function delegateServiceFee(address loan_) external view returns (uint256 delegateServiceFee_);

    /**
     *  @dev    Gets the delegate service fee for the given loan.
     *  @param  loan_               The address of the loan contract.
     *  @param  interval_           The time, in seconds, to get the proportional fee for
     *  @return delegateServiceFee_ The amount of delegate service fee to be paid.
     */
    function getDelegateServiceFeesForPeriod(address loan_, uint256 interval_) external view returns (uint256 delegateServiceFee_);

    /**
     *  @dev    Gets the sum of all origination fees for the given loan.
     *  @param  loan_               The address of the loan contract.
     *  @param  principalRequested_ The amount of principal requested in the loan.
     *  @return originationFees_    The amount of origination fees to be paid.
     */
    function getOriginationFees(address loan_, uint256 principalRequested_) external view returns (uint256 originationFees_);

    /**
     *  @dev    Gets the platform origination fee value for the given loan.
     *  @param  loan_                   The address of the loan contract.
     *  @param  principalRequested_     The amount of principal requested in the loan.
     *  @return platformOriginationFee_ The amount of platform origination fee to be paid.
     */
    function getPlatformOriginationFee(address loan_, uint256 principalRequested_) external view returns (uint256 platformOriginationFee_);

    /**
     *  @dev    Gets the delegate service fee for the given loan.
     *  @param  loan_               The address of the loan contract.
     *  @param  principalRequested_ The amount of principal requested in the loan.
     *  @param  interval_           The time, in seconds, to get the proportional fee for
     *  @return platformServiceFee_ The amount of platform service fee to be paid.
     */
    function getPlatformServiceFeeForPeriod(
        address loan_,
        uint256 principalRequested_,
        uint256 interval_
    ) external view returns (uint256 platformServiceFee_);

    /**
     *  @dev    Gets the service fees for the given interval.
     *  @param  loan_                 The address of the loan contract.
     *  @param  numberOfPayments_     The number of payments being paid.
     *  @return delegateServiceFee_   The amount of delegate service fee to be paid.
     *  @return delegateRefinanceFee_ The amount of delegate refinance fee to be paid.
     *  @return platformServiceFee_   The amount of platform service fee to be paid.
     *  @return platformRefinanceFee_ The amount of platform refinance fee to be paid.
     */
    function getServiceFeeBreakdown(address loan_, uint256 numberOfPayments_) external view returns (
        uint256 delegateServiceFee_,
        uint256 delegateRefinanceFee_,
        uint256 platformServiceFee_,
        uint256 platformRefinanceFee_
    );

    /**
     *  @dev    Gets the service fees for the given interval.
     *  @param  loan_             The address of the loan contract.
     *  @param  numberOfPayments_ The number of payments being paid.
     *  @return serviceFees_      The amount of platform service fee to be paid.
     */
    function getServiceFees(address loan_, uint256 numberOfPayments_) external view returns (uint256 serviceFees_);

    /**
     *  @dev    Gets the service fees for the given interval.
     *  @param  loan_        The address of the loan contract.
     *  @param  interval_    The time, in seconds, to get the proportional fee for
     *  @return serviceFees_ The amount of platform service fee to be paid.
     */
    function getServiceFeesForPeriod(address loan_, uint256 interval_) external view returns (uint256 serviceFees_);

    /**
     *  @dev    Gets the global contract address.
     *  @return globals_ The address of the global contract.
     */
    function globals() external view returns (address globals_);

    /**
     *  @dev    Gets the platform fee rate for the given loan.
     *  @param  loan_                        The address of the loan contract.
     *  @return platformRefinanceServiceFee_ The amount of platform service fee to be paid.
     */
    function platformRefinanceServiceFee(address loan_) external view returns (uint256 platformRefinanceServiceFee_);

    /**
     *  @dev    Gets the platform fee rate for the given loan.
     *  @param  loan_              The address of the loan contract.
     *  @return platformServiceFee The amount of platform service fee to be paid.
     */
    function platformServiceFee(address loan_) external view returns (uint256 platformServiceFee);

}