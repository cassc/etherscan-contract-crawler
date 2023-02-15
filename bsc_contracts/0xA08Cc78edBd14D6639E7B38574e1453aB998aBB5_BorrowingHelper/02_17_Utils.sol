// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

library Utils {
    uint private constant FEE_RATE_PRECISION = 10 ** 6;

    function toAmountBeforeTax(uint256 amount, uint24 feeRate) internal pure returns (uint) {
        uint denominator = FEE_RATE_PRECISION - feeRate;
        uint numerator = amount * FEE_RATE_PRECISION + denominator - 1;
        return numerator / denominator;
    }

    function toAmountAfterTax(uint256 amount, uint24 feeRate) internal pure returns (uint) {
        return (amount * (FEE_RATE_PRECISION - feeRate)) / FEE_RATE_PRECISION;
    }

    function minOf(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    function maxOf(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }
}