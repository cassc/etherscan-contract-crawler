// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

/// @title MapleRefinancer uses storage from Maple Loan.
interface IMapleRefinancer {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   The value for the service fee rate for the PoolDelegate (1e18 units).
     *  @param delegateServiceFeeRate_ The new value for delegateServiceFeeRate.
     */
    event DelegateServiceFeeRateSet(uint64 delegateServiceFeeRate_);

    /**
     *  @dev   A new value for gracePeriod has been set.
     *  @param gracePeriod_ The new value for gracePeriod.
     */
    event GracePeriodSet(uint256 gracePeriod_);

    /**
     *  @dev   A new value for interestRate has been set.
     *  @param interestRate_ The new value for interestRate.
     */
    event InterestRateSet(uint64 interestRate_);

    /**
     *  @dev   A new value for lateFeeRate has been set.
     *  @param lateFeeRate_ The new value for lateFeeRate.
     */
    event LateFeeRateSet(uint64 lateFeeRate_);

    /**
     *  @dev   A new value for lateInterestPremiumRate has been set.
     *  @param lateInterestPremiumRate_ The new value for lateInterestPremiumRate.
     */
    event LateInterestPremiumRateSet(uint64 lateInterestPremiumRate_);

    /**
     *  @dev   A new value for noticePeriod has been set.
     *  @param noticePeriod_ The new value for noticedPeriod.
     */
    event NoticePeriodSet(uint256 noticePeriod_);

    /**
     *  @dev   A new value for paymentInterval has been set.
     *  @param paymentInterval_ The new value for paymentInterval.
     */
    event PaymentIntervalSet(uint256 paymentInterval_);

    /**
     *  @dev   The value of the principal has been decreased.
     *  @param decreasedBy_ The amount of which the value was decreased by.
     */
    event PrincipalDecreased(uint256 decreasedBy_);

    /**
     *  @dev   The value of the principal has been increased.
     *  @param increasedBy_ The amount of which the value was increased by.
     */
    event PrincipalIncreased(uint256 increasedBy_);

    /**************************************************************************************************************************************/
    /*** Functions                                                                                                                      ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Function to decrease the principal during a refinance.
     *  @param amount_ The amount of which the value will decrease by.
     */
    function decreasePrincipal(uint256 amount_) external;

    /**
     *  @dev   Function to increase the principal during a refinance.
     *  @param amount_ The amount of which the value will increase by.
     */
    function increasePrincipal(uint256 amount_) external;

    /**
     *  @dev   Function to set the delegateServiceFeeRate during a refinance.
     *         The rate is denominated in 1e18 units.
     *  @param delegateServiceFeeRate_ The new value for delegateServiceFeeRate.
     */
    function setDelegateServiceFeeRate(uint64 delegateServiceFeeRate_) external;

    /**
     *  @dev   Function to set the gracePeriod during a refinance.
     *  @param gracePeriod_ The new value for gracePeriod.
     */
    function setGracePeriod(uint32 gracePeriod_) external;

    /**
     *  @dev   Function to set the interestRate during a refinance.
               The interest rate is measured with 18 decimals of precision.
     *  @param interestRate_ The new value for interestRate.
     */
    function setInterestRate(uint64 interestRate_) external;

    /**
     *  @dev   Function to set the lateFeeRate during a refinance.
     *  @param lateFeeRate_ The new value for lateFeeRate.
     */
    function setLateFeeRate(uint64 lateFeeRate_) external;

    /**
     *  @dev   Function to set the lateInterestPremiumRate during a refinance.
     *  @param lateInterestPremiumRate_ The new value for lateInterestPremiumRate.
     */
    function setLateInterestPremiumRate(uint64 lateInterestPremiumRate_) external;

    /**
     *  @dev   Function to set the noticePeriod during a refinance.
     *  @param noticePeriod_ The new value for noticePeriod.
     */
    function setNoticePeriod(uint32 noticePeriod_) external;

    /**
     *  @dev   Function to set the paymentInterval during a refinance.
     *         The interval is denominated in seconds.
     *  @param paymentInterval_ The new value for paymentInterval.
     */
    function setPaymentInterval(uint32 paymentInterval_) external;

}