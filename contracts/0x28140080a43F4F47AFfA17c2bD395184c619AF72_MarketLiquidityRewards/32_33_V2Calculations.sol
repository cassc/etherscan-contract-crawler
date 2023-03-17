pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: MIT

// Libraries
import "./NumbersLib.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import { Bid } from "../TellerV2Storage.sol";

enum PaymentType {
    EMI,
    Bullet
}

enum PaymentCycleType {
    Seconds,
    Monthly
}

library V2Calculations {
    using NumbersLib for uint256;

    /**
     * @notice Returns the timestamp of the last payment made for a loan.
     * @param _bid The loan bid struct to get the timestamp for.
     */
    function lastRepaidTimestamp(Bid storage _bid)
        internal
        view
        returns (uint32)
    {
        return
            _bid.loanDetails.lastRepaidTimestamp == 0
                ? _bid.loanDetails.acceptedTimestamp
                : _bid.loanDetails.lastRepaidTimestamp;
    }

    /**
     * @notice Calculates the amount owed for a loan.
     * @param _bid The loan bid struct to get the owed amount for.
     * @param _timestamp The timestamp at which to get the owed amount at.
     * @param _paymentCycleType The payment cycle type of the loan (Seconds or Monthly).
     */
    function calculateAmountOwed(
        Bid storage _bid,
        uint256 _timestamp,
        PaymentCycleType _paymentCycleType
    )
        internal
        view
        returns (
            uint256 owedPrincipal_,
            uint256 duePrincipal_,
            uint256 interest_
        )
    {
        // Total principal left to pay
        return
            calculateAmountOwed(
                _bid,
                lastRepaidTimestamp(_bid),
                _timestamp,
                _paymentCycleType
            );
    }

    function calculateAmountOwed(
        Bid storage _bid,
        uint256 _lastRepaidTimestamp,
        uint256 _timestamp,
        PaymentCycleType _paymentCycleType
    )
        internal
        view
        returns (
            uint256 owedPrincipal_,
            uint256 duePrincipal_,
            uint256 interest_
        )
    {
        owedPrincipal_ =
            _bid.loanDetails.principal -
            _bid.loanDetails.totalRepaid.principal;

        uint256 daysInYear = _paymentCycleType == PaymentCycleType.Monthly
            ? 360 days
            : 365 days;

        uint256 interestOwedInAYear = owedPrincipal_.percent(_bid.terms.APR);
        uint256 owedTime = _timestamp - uint256(_lastRepaidTimestamp);
        interest_ = (interestOwedInAYear * owedTime) / daysInYear;

        // Cast to int265 to avoid underflow errors (negative means loan duration has passed)
        int256 durationLeftOnLoan = int256(
            uint256(_bid.loanDetails.loanDuration)
        ) -
            (int256(_timestamp) -
                int256(uint256(_bid.loanDetails.acceptedTimestamp)));
        bool isLastPaymentCycle = durationLeftOnLoan <
            int256(uint256(_bid.terms.paymentCycle)) || // Check if current payment cycle is within or beyond the last one
            owedPrincipal_ + interest_ <= _bid.terms.paymentCycleAmount; // Check if what is left to pay is less than the payment cycle amount

        if (_bid.paymentType == PaymentType.Bullet) {
            if (isLastPaymentCycle) {
                duePrincipal_ = owedPrincipal_;
            }
        } else {
            // Default to PaymentType.EMI
            // Max payable amount in a cycle
            // NOTE: the last cycle could have less than the calculated payment amount
            uint256 maxCycleOwed = isLastPaymentCycle
                ? owedPrincipal_ + interest_
                : _bid.terms.paymentCycleAmount;

            // Calculate accrued amount due since last repayment
            uint256 owedAmount = (maxCycleOwed * owedTime) /
                _bid.terms.paymentCycle;
            duePrincipal_ = Math.min(owedAmount - interest_, owedPrincipal_);
        }
    }

    /**
     * @notice Calculates the amount owed for a loan for the next payment cycle.
     * @param _type The payment type of the loan.
     * @param _cycleType The cycle type set for the loan. (Seconds or Monthly)
     * @param _principal The starting amount that is owed on the loan.
     * @param _duration The length of the loan.
     * @param _paymentCycle The length of the loan's payment cycle.
     * @param _apr The annual percentage rate of the loan.
     */
    function calculatePaymentCycleAmount(
        PaymentType _type,
        PaymentCycleType _cycleType,
        uint256 _principal,
        uint32 _duration,
        uint32 _paymentCycle,
        uint16 _apr
    ) internal returns (uint256) {
        uint256 daysInYear = _cycleType == PaymentCycleType.Monthly
            ? 360 days
            : 365 days;
        if (_type == PaymentType.Bullet) {
            return
                _principal.percent(_apr).percent(
                    uint256(_paymentCycle).ratioOf(daysInYear, 10),
                    10
                );
        }
        // Default to PaymentType.EMI
        return
            NumbersLib.pmt(
                _principal,
                _duration,
                _paymentCycle,
                _apr,
                daysInYear
            );
    }
}