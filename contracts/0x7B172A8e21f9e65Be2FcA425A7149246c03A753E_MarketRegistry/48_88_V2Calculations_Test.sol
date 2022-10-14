// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@mangrovedao/hardhat-test-solidity/test.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "hardhat/console.sol";

import "./Testable.sol";
import "../TellerV2.sol";

contract V2Calculations_Test is Testable {
    using Arrays for uint256[];
    using EnumerableSet for EnumerableSet.UintSet;

    TellerV2.Bid __bid;
    EnumerableSet.UintSet cyclesToSkip;
    uint256[] cyclesWithExtraPayments;
    uint256[] cyclesWithExtraPaymentsAmounts;

    constructor() {
        __bid.loanDetails.principal = 100000e6; // 100k
        __bid.loanDetails.loanDuration = 365 days * 3; // 3 years
        __bid.terms.paymentCycle = 365 days / 12; // 1 month
        __bid.terms.APR = 1000; // 10.0%
    }

    function setup_beforeAll() public {
        delete cyclesToSkip;
        delete cyclesWithExtraPayments;
        delete cyclesWithExtraPaymentsAmounts;
    }

    // EMI loan
    function _01_calculateAmountOwed_test() public {
        cyclesToSkip.add(2);
        cyclesWithExtraPayments = [3, 4];
        cyclesWithExtraPaymentsAmounts = [25000e6, 25000e6];

        calculateAmountOwed_runner(18, V2Calculations.PaymentType.EMI);
    }

    // EMI loan
    function _02_calculateAmountOwed_test() public {
        cyclesToSkip.add(3);
        cyclesToSkip.add(4);
        cyclesToSkip.add(5);

        calculateAmountOwed_runner(36, V2Calculations.PaymentType.EMI);
    }

    // EMI loan
    function _03_calculateAmountOwed_test() public {
        cyclesWithExtraPayments = [3, 7];
        cyclesWithExtraPaymentsAmounts = [35000e6, 20000e6];

        calculateAmountOwed_runner(16, V2Calculations.PaymentType.EMI);
    }

    // Bullet loan
    function _04_calculateAmountOwed_test() public {
        cyclesToSkip.add(6);
        calculateAmountOwed_runner(36, V2Calculations.PaymentType.Bullet);
    }

    // Bullet loan
    function _05_calculateAmountOwed_test() public {
        cyclesToSkip.add(12);
        cyclesWithExtraPayments = [1, 8];
        cyclesWithExtraPaymentsAmounts = [15000e6, 10000e6];
        calculateAmountOwed_runner(36, V2Calculations.PaymentType.Bullet);
    }

    function calculateAmountOwed_runner(
        uint256 expectedTotalCycles,
        V2Calculations.PaymentType _paymentType
    ) private {
        // Calculate payment cycle amount
        uint256 paymentCycleAmount = V2Calculations.calculatePaymentCycleAmount(
            _paymentType,
            __bid.loanDetails.principal,
            __bid.loanDetails.loanDuration,
            __bid.terms.paymentCycle,
            __bid.terms.APR
        );

        // Set the bid's payment cycle amount
        __bid.terms.paymentCycleAmount = paymentCycleAmount;
        // Set accepted bid timestamp to now
        __bid.loanDetails.acceptedTimestamp = uint32(block.timestamp);

        uint256 nowTimestamp = block.timestamp;
        uint256 skippedPaymentCounter;
        uint256 owedPrincipal = __bid.loanDetails.principal;
        uint256 cycleCount = Math.ceilDiv(
            __bid.loanDetails.loanDuration,
            __bid.terms.paymentCycle
        );
        uint256 cycleIndex;
        while (owedPrincipal > 0) {
            // Increment cycle index
            cycleIndex++;

            // Increase timestamp
            nowTimestamp += __bid.terms.paymentCycle;

            uint256 duePrincipal;
            uint256 interest;
            (owedPrincipal, duePrincipal, interest) = V2Calculations
                .calculateAmountOwed(__bid, nowTimestamp);

            // Check if we should skip this cycle for payments
            if (cyclesToSkip.length() > 0) {
                if (cyclesToSkip.contains(cycleIndex)) {
                    // Add this cycle's payment amount to the next cycle's expected payment
                    skippedPaymentCounter++;
                    continue;
                }
            }

            skippedPaymentCounter = 0;

            uint256 extraPaymentAmount;
            // Add additional payment amounts for cycles
            if (cyclesWithExtraPayments.length > 0) {
                uint256 index = cyclesWithExtraPayments.findUpperBound(
                    cycleIndex
                );
                if (
                    index < cyclesWithExtraPayments.length &&
                    cyclesWithExtraPayments[index] == cycleIndex
                ) {
                    extraPaymentAmount = cyclesWithExtraPaymentsAmounts[index];
                }
            }

            // Mark repayment amounts
            uint256 principalPayment;
            principalPayment = duePrincipal + extraPaymentAmount;
            if (principalPayment > 0) {
                __bid.loanDetails.totalRepaid.principal += principalPayment;
                // Subtract principal owed for while loop execution check
                owedPrincipal -= principalPayment;
            }

            __bid.loanDetails.totalRepaid.interest += interest;

            // Set last repaid time
            __bid.loanDetails.lastRepaidTimestamp = uint32(nowTimestamp);
        }
        Test.eq(
            cycleIndex,
            expectedTotalCycles,
            "Expected number of cycles incorrect"
        );
        Test.eq(
            cycleIndex <= cycleCount + 1,
            true,
            "Payment cycle exceeded agreed terms"
        );
    }

    function calculateAmountOwed_test() public {
        uint256 principal = 24486571879936808846;
        uint256 repaidPrincipal = 23410087846643631232;
        uint16 interestRate = 3000;

        (uint256 _owedPrincipal, uint256 _duePrincipal, uint256 _interest) = V2Calculations
            .calculateAmountOwed(
                principal, //owed principal
                repaidPrincipal,
                interestRate,
                8567977538702439153, //payment cycle amount
                2592000, ///payment Cycle
                1658159355, // last repaid timestamp
                1663189241, //timestamp
                1646159355, // accepted timestamp
                __bid.loanDetails.loanDuration, // duration
                V2Calculations.PaymentType.EMI // market payment type
            );

        console.log("calc amt owed test ");
        console.log(_owedPrincipal);
        console.log(_duePrincipal);

        Test.eq(
            _owedPrincipal,
            1076484033293177614,
            "Expected number of cycles incorrect"
        );
        Test.eq(
            _duePrincipal,
            1076484033293177614,
            "Expected number of cycles incorrect"
        );
    }

    function calculateBulletAmountOwed_test() public {
        uint256 _principal = 100000e6;
        uint256 _repaidPrincipal = 0;
        uint16 _apr = 3000;
        uint256 _paymentCycleAmount = V2Calculations
            .calculatePaymentCycleAmount(
                V2Calculations.PaymentType.Bullet,
                _principal,
                365 days,
                365 days / 12,
                _apr
            );
        uint256 _acceptedTimestamp = 1646159355;
        uint256 _lastRepaidTimestamp = _acceptedTimestamp;

        // Within the first payment cycle
        uint256 _timestamp = _acceptedTimestamp + ((365 days / 12) / 2);

        (uint256 _owedPrincipal, uint256 _duePrincipal, uint256 _interest) = V2Calculations
            .calculateAmountOwed(
                _principal,
                _repaidPrincipal,
                _apr,
                _paymentCycleAmount,
                365 days / 12, // paymentCycle
                _lastRepaidTimestamp,
                _timestamp,
                _acceptedTimestamp,
                365 days, // loan duration
                V2Calculations.PaymentType.Bullet
            );

        Test.eq(
            _owedPrincipal,
            _principal,
            "First cycle bullet owed principal incorrect"
        );
        Test.eq(_duePrincipal, 0, "First cycle bullet due principal incorrect");
        Test.eq(_interest, 1250000000, "First cycle bullet interest incorrect");

        // Within random payment cycle
        _timestamp = _acceptedTimestamp + ((365 days / 12) * 3);

        (_owedPrincipal, _duePrincipal, _interest) = V2Calculations
            .calculateAmountOwed(
                _principal,
                _repaidPrincipal,
                _apr,
                _paymentCycleAmount,
                365 days / 12, // paymentCycle
                _lastRepaidTimestamp,
                _timestamp,
                _acceptedTimestamp,
                365 days, // loan duration
                V2Calculations.PaymentType.Bullet
            );

        Test.eq(
            _owedPrincipal,
            _principal,
            "Second cycle bullet Owed principal incorrect"
        );
        Test.eq(_duePrincipal, 0, "Second cycle bullet principal incorrect");
        Test.eq(
            _interest,
            7500000000,
            "Second cycle bullet interest incorrect"
        );

        // Last payment cycle
        _timestamp = _acceptedTimestamp + 360 days;

        (_owedPrincipal, _duePrincipal, _interest) = V2Calculations
            .calculateAmountOwed(
                _principal,
                _repaidPrincipal,
                _apr,
                _paymentCycleAmount,
                365 days / 12, // paymentCycle
                _lastRepaidTimestamp,
                _timestamp,
                _acceptedTimestamp,
                365 days, // loan duration
                V2Calculations.PaymentType.Bullet
            );

        Test.eq(
            _owedPrincipal,
            _principal,
            "Final cycle bullet Owed principal incorrect"
        );
        Test.eq(
            _duePrincipal,
            _principal,
            "Final cycle bullet principal incorrect"
        );
        Test.eq(
            _interest,
            29589041095,
            "Final cycle bullet interest incorrect"
        );

        // Beyond last payment cycle (checks for overflow protection)
        _timestamp = _acceptedTimestamp + 365 days * 2;

        (_owedPrincipal, _duePrincipal, _interest) = V2Calculations
            .calculateAmountOwed(
                _principal,
                _repaidPrincipal,
                _apr,
                _paymentCycleAmount,
                365 days / 12, // paymentCycle
                _lastRepaidTimestamp,
                _timestamp,
                _acceptedTimestamp,
                365 days, // loan duration
                V2Calculations.PaymentType.Bullet
            );

        Test.eq(
            _owedPrincipal,
            _principal,
            "Final cycle bullet Owed principal incorrect"
        );
        Test.eq(
            _duePrincipal,
            _principal,
            "Final cycle bullet principal incorrect"
        );
        Test.eq(
            _interest,
            ((_principal * _apr) / 10000) * 2,
            "Final cycle bullet interest incorrect"
        );
    }
}