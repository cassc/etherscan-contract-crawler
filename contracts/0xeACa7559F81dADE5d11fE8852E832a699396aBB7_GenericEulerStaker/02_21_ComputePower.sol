// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

library ComputePower {
    /// @notice Calculates (1+x)**n where x is a small number in base `base`
    /// @param ratePerSecond x value
    /// @param exp n value
    /// @param base Base in which the `ratePerSecond` is
    /// @dev This function avoids expensive exponentiation and the calculation is performed using a binomial approximation
    /// (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
    /// @dev This function was mostly inspired from Aave implementation and comes with the advantage of a great gas cost
    /// reduction with respect to the base power implementation
    function computePower(
        uint256 ratePerSecond,
        uint256 exp,
        uint256 base
    ) internal pure returns (uint256) {
        if (exp == 0 || ratePerSecond == 0) return base;
        uint256 halfBase = base / 2;
        uint256 expMinusOne = exp - 1;
        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;
        uint256 basePowerTwo = (ratePerSecond * ratePerSecond + halfBase) / base;
        uint256 basePowerThree = (basePowerTwo * ratePerSecond + halfBase) / base;
        uint256 secondTerm = (exp * expMinusOne * basePowerTwo) / 2;
        uint256 thirdTerm = (exp * expMinusOne * expMinusTwo * basePowerThree) / 6;
        return base + ratePerSecond * exp + secondTerm + thirdTerm;
    }
}