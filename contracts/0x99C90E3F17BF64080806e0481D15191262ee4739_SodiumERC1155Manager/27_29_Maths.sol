// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// A library for performing calculations used by the Sodium Protocol

// Interest
// - Meta-lenders earn interest on the bigger of the following:
//   - the loan's duration
//   - half the borrowers requested loan length
// - Interest increases discretely every hour

// Fees:
// - There are two components to protocol fees:
//   - The borrower pays a fee, equal to a fraction of the interest earned, on top of that interest
//   - This amount is also taken from the interest itself
// - Fraction is feeNumerator / feeDenominator

library Maths {
    function calculateInterestAndFee(
        uint256 principal,
        uint256 APR,
        uint256 duration,
        uint256 feeInBasisPoints
    ) internal pure returns (uint256, uint256) {
        // divide by 10000 because apr expressed in 4 digits
        uint256 baseInterest = ((principal * APR * duration) / 10000) / 365 days;
        uint256 baseFee = (baseInterest * feeInBasisPoints) / 10000;

        return (baseInterest - baseFee, baseFee * 2);
    }

    function principalPlusInterest(uint256 principal, uint256 APR, uint256 duration) internal pure returns (uint256) {
        // divide by 10000 because apr expressed in 4 digits
        uint256 interest = ((principal * APR * duration) / 10000) / 365 days;
        return principal + interest;
    }

    // Calculates the maximum principal reduction for an input amount of available funds
    function partialPaymentParameters(
        uint256 available,
        uint256 APR,
        uint256 duration,
        uint256 feeInBasisPoints
    ) internal pure returns (uint256, uint256, uint256) {
        uint256 oneYearInterest = (available * APR) / 10000;
        uint256 durationInterest = (oneYearInterest * duration) / 365 days;

        uint256 principalReduction = available - durationInterest;
        uint256 absoluteProtocolFee = (durationInterest * feeInBasisPoints) / 10000;

        // fee is deducted from both sides: lender and borrower
        uint256 interestMinusFee = durationInterest - absoluteProtocolFee;
        uint256 reductionMinusFee = principalReduction - absoluteProtocolFee;

        return (reductionMinusFee, interestMinusFee, absoluteProtocolFee * 2);
    }
}