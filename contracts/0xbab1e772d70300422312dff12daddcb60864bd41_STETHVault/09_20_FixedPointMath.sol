// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

library FixedPointMath {
    using FixedPointMath for uint256;

    error FixedPointMath__DivByZero();

    struct Fractional {
        uint256 numerator;
        uint256 denominator;
    }

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256) {
        if (denominator == 0) revert FixedPointMath__DivByZero();
        return (x * y) / denominator;
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256) {
        if (denominator == 0) revert FixedPointMath__DivByZero();
        uint256 numerator = x * y;
        return numerator / denominator + (numerator % denominator > 0 ? 1 : 0);
    }

    function mulDivUp(uint256 x, Fractional memory y) internal pure returns (uint256) {
        return x.mulDivUp(y.numerator, y.denominator);
    }

    function mulDivDown(uint256 x, Fractional memory y) internal pure returns (uint256) {
        return x.mulDivDown(y.numerator, y.denominator);
    }

    function mulDivUp(Fractional memory x, uint256 y) internal pure returns (uint256) {
        return x.numerator.mulDivUp(y, x.denominator);
    }

    function mulDivDown(Fractional memory x, uint256 y) internal pure returns (uint256) {
        return x.numerator.mulDivDown(y, x.denominator);
    }

    function fractionRoundUp(Fractional memory x) internal pure returns (uint256) {
        return x.numerator.mulDivUp(1, x.denominator);
    }

    function fractionRoundDown(Fractional memory x) internal pure returns (uint256) {
        return x.numerator.mulDivDown(1, x.denominator);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
}