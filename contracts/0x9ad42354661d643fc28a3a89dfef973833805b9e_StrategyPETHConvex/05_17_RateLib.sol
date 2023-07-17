// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

library RateLib {
    error InvalidRate();

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    function isValid(Rate memory _rate) internal pure returns (bool) {
        return _rate.denominator != 0;
    }

    function isZero(Rate memory _rate) internal pure returns (bool) {
        return _rate.numerator == 0;
    }

    function isAboveOne(Rate memory _rate) internal pure returns (bool) {
        return _rate.numerator > _rate.denominator;
    }

    function isBelowOne(Rate memory _rate) internal pure returns (bool) {
        return _rate.denominator > _rate.numerator;
    }

    function isOne(Rate memory _rate) internal pure returns (bool) {
        return _rate.numerator == _rate.denominator;
    }

    function greaterThan(
        Rate memory _r1,
        Rate memory _r2
    ) internal pure returns (bool) {
        return
            _r1.numerator * _r2.denominator > _r2.numerator * _r1.denominator;
    }

    function sum(
        Rate memory _r1,
        Rate memory _r2
    ) internal pure returns (Rate memory) {
        return
            Rate({
                numerator: _r1.numerator *
                    _r2.denominator +
                    _r1.denominator *
                    _r2.numerator,
                denominator: _r1.denominator * _r2.denominator
            });
    }

    function calculate(
        Rate memory _rate,
        uint256 _num
    ) internal pure returns (uint256) {
        return (_num * _rate.numerator) / _rate.denominator;
    }
}