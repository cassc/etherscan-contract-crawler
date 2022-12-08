// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IFeeManager.sol";
import "./HumaConfig.sol";
import "./Errors.sol";
import {BaseStructs as BS} from "./libraries/BaseStructs.sol";
import "hardhat/console.sol";

/**
 *
 */
contract BaseFeeManager is IFeeManager, Ownable {
    using BS for BS.CreditRecord;

    // Divider to convert BPS to percentage
    uint256 private constant HUNDRED_PERCENT_IN_BPS = 10000;
    // Divider to get monthly interest rate from APR BPS. 10000 * 12
    uint256 private constant SECONDS_IN_A_YEAR = 365 days;
    uint256 private constant SECONDS_IN_A_DAY = 1 days;
    uint256 private constant MAX_PERIODS = 360; // 30 years monthly loan

    /// Part of platform fee, charged as a flat amount when a borrow happens
    uint256 public frontLoadingFeeFlat;

    /// Part of platform fee, charged as a % of the borrowing amount when a borrow happens
    uint256 public frontLoadingFeeBps;

    /// Part of late fee, charged as a flat amount when a payment is late
    uint256 public lateFeeFlat;

    /// Part of late fee, charged as % of the totaling outstanding balance when a payment is late
    uint256 public lateFeeBps;

    // membership fee per pay period. It is a flat fee
    uint256 public membershipFee;

    ///The min % of the outstanding principal to be paid in the statement for each each period
    uint256 public minPrincipalRateInBps;

    event FeeChanged(
        uint256 frontLoandingFeeFlat,
        uint256 frontLoadingFeeBps,
        uint256 lateFeeFlat,
        uint256 lateFeeBps,
        uint256 membershipFee
    );

    event MinPrincipalRateChanged(uint256 minPrincipalRateInBps);

    /**
     * @notice Sets the standard front loading and late fee policy for the fee manager
     * @param _frontLoadingFeeFlat flat fee portion of the front loading fee
     * @param _frontLoadingFeeBps a fee in the percentage of a new borrowing
     * @param _lateFeeFlat flat fee portion of the late
     * @param _lateFeeBps a fee in the percentage of the outstanding balance
     * @dev Only owner can make this setting
     */
    function setFees(
        uint256 _frontLoadingFeeFlat,
        uint256 _frontLoadingFeeBps,
        uint256 _lateFeeFlat,
        uint256 _lateFeeBps,
        uint256 _membershipFee
    ) external virtual override onlyOwner {
        frontLoadingFeeFlat = _frontLoadingFeeFlat;
        frontLoadingFeeBps = _frontLoadingFeeBps;
        lateFeeFlat = _lateFeeFlat;
        lateFeeBps = _lateFeeBps;
        membershipFee = _membershipFee;
        emit FeeChanged(
            _frontLoadingFeeFlat,
            _frontLoadingFeeBps,
            _lateFeeFlat,
            _lateFeeBps,
            _membershipFee
        );
    }

    /**
     * @notice Sets the min percentage of principal to be paid in each billing period
     * @param _minPrincipalRateInBps the min % in unit of bps. For example, 5% will be 500
     * @dev Only owner can make this setting
     * @dev There is a global limit of 5000 bps (50%).
     */
    function setMinPrincipalRateInBps(uint256 _minPrincipalRateInBps)
        external
        virtual
        override
        onlyOwner
    {
        if (_minPrincipalRateInBps >= 5000) revert Errors.minPrincipalPaymentRateSettingTooHigh();
        minPrincipalRateInBps = _minPrincipalRateInBps;
        emit MinPrincipalRateChanged(_minPrincipalRateInBps);
    }

    /**
     * @notice Computes the amount to be offseted due to in-cycle drawdown or principal payment
     * @dev Correction is used when there is change to the principal in the middle of the cycle
     * due to drawdown or principal payment. Since Huma computes the interest at the beginning
     * of each cycle, if there is a drawdown, the interest for this extra borrowing is not
     * billed, there will be a positive correction to be added in the next bill. Conversely,
     * since the interest has been computed for the entire cycle, if there is principal payment
     * in the middle, some of the interest should be refunded. It will be marked as negative
     * correction and be subtracted in the next bill.
     */
    function calcCorrection(
        uint256 dueDate,
        uint256 aprInBps,
        uint256 amount
    ) external view virtual override returns (uint256 correction) {
        // rounding to days
        uint256 remainingTime = dueDate - block.timestamp;

        return (amount * aprInBps * remainingTime) / SECONDS_IN_A_YEAR / HUNDRED_PERCENT_IN_BPS;
    }

    /**
     * @notice Computes the front loading fee including both the flat fee and percentage fee
     * @param _amount the borrowing amount
     * @return fees the amount of fees to be charged for this borrowing
     */
    function calcFrontLoadingFee(uint256 _amount)
        public
        view
        virtual
        override
        returns (uint256 fees)
    {
        fees = frontLoadingFeeFlat;
        if (frontLoadingFeeBps > 0)
            fees += (_amount * frontLoadingFeeBps) / HUNDRED_PERCENT_IN_BPS;
    }

    /**
     * @notice Computes the late fee including both the flat fee and percentage fee
     * @param dueDate the due date of the payment
     * @param totalDue the amount that is due
     * @param totalBalance the total balance including amount due and unbilled principal
     * @return fees the amount of late fees to be charged
     * @dev Charges only if 1) there is outstanding due, 2) the due date has passed
     */
    function calcLateFee(
        uint256 dueDate,
        uint256 totalDue,
        uint256 totalBalance
    ) public view virtual override returns (uint256 fees) {
        if (block.timestamp > dueDate && totalDue > 0) {
            fees = lateFeeFlat;
            if (lateFeeBps > 0) fees += (totalBalance * lateFeeBps) / HUNDRED_PERCENT_IN_BPS;
        }
    }

    /**
     * @notice Apply front loading fee, distribute the total amount to borrower, pool, & protocol
     * @param borrowAmount the amount of the borrowing
     * @return amtToBorrower the amount that the borrower can take
     * @return platformFees the platform charges
     * @dev the protocol always takes a percentage of the total fee generated
     */
    function distBorrowingAmount(uint256 borrowAmount)
        external
        view
        returns (uint256 amtToBorrower, uint256 platformFees)
    {
        // Calculate platform fee, which includes protocol fee and pool fee
        platformFees = calcFrontLoadingFee(borrowAmount);

        if (borrowAmount < platformFees) revert Errors.borrowingAmountLessThanPlatformFees();

        amtToBorrower = borrowAmount - platformFees;

        return (amtToBorrower, platformFees);
    }

    /**
     * @notice Gets the current total due, fees and interest due, and payoff amount.
     * Because there is no "cron" kind of mechanism, it is possible that the account is behind
     * for multiple cycles due to a lack of activities. This function will traverse through
     * these cycles to get the most up-to-date due information.
     * @dev This is a view only function, it does not update the account status. It is used to
     * help the borrowers to get their balances without paying gases.
     * @dev the difference between totalDue and feesAndInterestDue is required principal payment
     * @dev payoffAmount is good until the next statement date. It includes the interest for the
     * entire current/new billing period. We will ask for allowance of the total payoff amount,
     * but if the borrower pays off before the next due date, we will subtract the interest saved
     * and only transfer an amount lower than the original payoff estimate.
     * @dev please note the first due date is set after the initial drawdown. All the future due
     * dates are computed by adding multiples of the payment interval to the first due date.
     * @param _cr the credit record associated the account
     * @return periodsPassed the number of billing periods has passed since the last statement.
     * If it is within the same period, it will be 0.
     * @return feesAndInterestDue the sum of fees and interest due. If multiple cycles have passed,
     * this amount is not necessarily the total fees and interest charged. It only returns the amount
     * that is due currently.
     * @return totalDue amount due in this period, it includes fees, interest, and min principal
     */
    function getDueInfo(
        BaseStructs.CreditRecord memory _cr,
        BaseStructs.CreditRecordStatic memory _crStatic
    )
        public
        view
        virtual
        override
        returns (
            uint256 periodsPassed,
            uint96 feesAndInterestDue,
            uint96 totalDue,
            uint96 unbilledPrincipal,
            int96 totalCharges
        )
    {
        // Directly returns if it is still within the current period
        if (block.timestamp <= _cr.dueDate) {
            return (0, _cr.feesAndInterestDue, _cr.totalDue, _cr.unbilledPrincipal, 0);
        }

        // Computes how many billing periods have passed. 1+ is needed since Solidity always
        // round to zero. When it is exactly at a billing cycle, it is desirable to 1+ as well
        if (_cr.dueDate > 0) {
            periodsPassed =
                1 +
                (block.timestamp - _cr.dueDate) /
                (_crStatic.intervalInDays * SECONDS_IN_A_DAY);
            // No credit line has more than 360 periods. If it is longer than that, something
            // is wrong. Set it to 361 so that the non view function can emit an event.
            assert(periodsPassed <= MAX_PERIODS);
        } else {
            periodsPassed = 1;
        }

        /**
         * Loops through the cycles as we would generate statements for each cycle.
         * The logic for each iteration is as follows:
         * 1. Calcuate late fee if it is past due based on outstanding principal and due
         * 2. Add membership fee
         * 3  Add outstanding due amount and corrections to the unbilled principal
         *    as the new base for principal
         * 4. Calcuate interest for this new cycle using the new principal
         * 5. Calculate the principal due, and minus it from the unbilled principal amount
         */
        uint256 fees = 0;
        uint256 interest = 0;

        for (uint256 i = 0; i < periodsPassed; i++) {
            // step 1. late fee calculation
            if (_cr.totalDue > 0)
                fees = calcLateFee(
                    _cr.dueDate + i * _crStatic.intervalInDays * SECONDS_IN_A_DAY,
                    _cr.totalDue,
                    _cr.unbilledPrincipal + _cr.totalDue
                );

            // step 2. membership fee
            fees += membershipFee;

            // step 3. adding dues to principal
            _cr.unbilledPrincipal += _cr.totalDue;
            // Negative correction is generated by in-cycle payments only.
            // Positive correction is generated by in-cycle drawdowns only.
            // Incorporate pending corrections into principals
            if (_cr.correction != 0) {
                totalCharges += _cr.correction;
                if (_cr.correction < 0) {
                    uint96 correctionAbs = uint96(0 - _cr.correction);
                    // Note: If _cr.unbilledPrincipal is less than abs(correction), the account
                    // should have been paid off in the last payment. Thus the assertion below.
                    // One outlier case is drastic interest hike at the time of payments made.
                    //
                    assert(_cr.unbilledPrincipal > correctionAbs);
                    _cr.unbilledPrincipal -= correctionAbs;
                } else _cr.unbilledPrincipal += uint96(_cr.correction);
                _cr.correction = 0;
            }

            // step 4. compute interest
            interest =
                (_cr.unbilledPrincipal *
                    _crStatic.aprInBps *
                    _crStatic.intervalInDays *
                    SECONDS_IN_A_DAY) /
                SECONDS_IN_A_YEAR /
                HUNDRED_PERCENT_IN_BPS;

            // step 5. compute principal due and adjust unbilled principal
            uint256 principalToBill = (_cr.unbilledPrincipal * minPrincipalRateInBps) /
                HUNDRED_PERCENT_IN_BPS;
            _cr.feesAndInterestDue = uint96(fees + interest);
            totalCharges += int96(uint96(fees + interest));
            _cr.totalDue = uint96(fees + interest + principalToBill);
            _cr.unbilledPrincipal = uint96(_cr.unbilledPrincipal - principalToBill);
        }

        // If passed final period, all principal is due
        if (periodsPassed >= _cr.remainingPeriods) {
            _cr.totalDue += _cr.unbilledPrincipal;
            _cr.unbilledPrincipal = 0;
        }

        return (
            periodsPassed,
            _cr.feesAndInterestDue,
            _cr.totalDue,
            _cr.unbilledPrincipal,
            totalCharges
        );
    }

    /**
     * @notice Gets the fee structure for the pool
     * @param _frontLoadingFeeFlat flat fee portion of the front loading fee
     * @param _frontLoadingFeeBps a fee in the percentage of a new borrowing
     * @param _lateFeeFlat flat fee portion of the late
     * @param _lateFeeBps a fee in the percentage of the outstanding balance
     */
    function getFees()
        external
        view
        virtual
        override
        returns (
            uint256 _frontLoadingFeeFlat,
            uint256 _frontLoadingFeeBps,
            uint256 _lateFeeFlat,
            uint256 _lateFeeBps,
            uint256 _membershipFee
        )
    {
        return (frontLoadingFeeFlat, frontLoadingFeeBps, lateFeeFlat, lateFeeBps, membershipFee);
    }
}