pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: MIT

// Libraries
import "./NumbersLib.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import { Bid } from "../TellerV2Storage.sol";
import { BokkyPooBahsDateTimeLibrary as BPBDTL } from "./DateTimeLib.sol";

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

        bool isLastPaymentCycle;
        {
            uint256 lastPaymentCycleDuration = _bid.loanDetails.loanDuration %
                _bid.terms.paymentCycle;
            if (lastPaymentCycleDuration == 0) {
                lastPaymentCycleDuration = _bid.terms.paymentCycle;
            }

            uint256 endDate = uint256(_bid.loanDetails.acceptedTimestamp) +
                uint256(_bid.loanDetails.loanDuration);
            uint256 lastPaymentCycleStart = endDate -
                uint256(lastPaymentCycleDuration);

            isLastPaymentCycle =
                uint256(_timestamp) > lastPaymentCycleStart ||
                owedPrincipal_ + interest_ <= _bid.terms.paymentCycleAmount;
        }

        if (_bid.paymentType == PaymentType.Bullet) {
            if (isLastPaymentCycle) {
                duePrincipal_ = owedPrincipal_;
            }
        } else {
            // Default to PaymentType.EMI
            // Max payable amount in a cycle
            // NOTE: the last cycle could have less than the calculated payment amount

            uint256 owedAmount = isLastPaymentCycle
                ? owedPrincipal_ + interest_
                : (_bid.terms.paymentCycleAmount * owedTime) /
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

    function calculateNextDueDate(
        uint32 _acceptedTimestamp,
        uint32 _paymentCycle,
        uint32 _loanDuration,
        uint32 _lastRepaidTimestamp,
        PaymentCycleType _bidPaymentCycleType
    ) public view returns (uint32 dueDate_) {
        // Calculate due date if payment cycle is set to monthly
        if (_bidPaymentCycleType == PaymentCycleType.Monthly) {
            // Calculate the cycle number the last repayment was made
            uint256 lastPaymentCycle = BPBDTL.diffMonths(
                _acceptedTimestamp,
                _lastRepaidTimestamp
            );
            if (
                BPBDTL.getDay(_lastRepaidTimestamp) >
                BPBDTL.getDay(_acceptedTimestamp)
            ) {
                lastPaymentCycle += 2;
            } else {
                lastPaymentCycle += 1;
            }

            dueDate_ = uint32(
                BPBDTL.addMonths(_acceptedTimestamp, lastPaymentCycle)
            );
        } else if (_bidPaymentCycleType == PaymentCycleType.Seconds) {
            // Start with the original due date being 1 payment cycle since bid was accepted
            dueDate_ = _acceptedTimestamp + _paymentCycle;
            // Calculate the cycle number the last repayment was made
            uint32 delta = _lastRepaidTimestamp - _acceptedTimestamp;
            if (delta > 0) {
                uint32 repaymentCycle = uint32(
                    Math.ceilDiv(delta, _paymentCycle)
                );
                dueDate_ += (repaymentCycle * _paymentCycle);
            }
        }

        uint32 endOfLoan = _acceptedTimestamp + _loanDuration;
        //if we are in the last payment cycle, the next due date is the end of loan duration
        if (dueDate_ > endOfLoan) {
            dueDate_ = endOfLoan;
        }
    }
}