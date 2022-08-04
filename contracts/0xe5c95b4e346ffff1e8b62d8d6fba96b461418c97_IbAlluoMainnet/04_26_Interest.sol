// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2018 Rain <[email protected]> and Centrifuge, referencing MakerDAO dss => https://github.com/makerdao/dss/blob/master/src/pot.sol
pragma solidity >=0.5.15;

import "./Math.sol";

contract Interest is Math {
    // @notice This function provides compounding in seconds
    // @param chi Accumulated interest rate over time
    // @param ratePerSecond Interest rate accumulation per second in RAD(10ˆ27)
    // @param lastUpdated When the interest rate was last updated
    // @param pie Total sum of all amounts accumulating under one interest rate, divided by that rate
    // @return The new accumulated rate, as well as the difference between the debt calculated with the old and new accumulated rates.
    function compounding(uint chi, uint ratePerSecond, uint lastUpdated, uint pie) private view returns (uint, uint) {
        require(block.timestamp >= lastUpdated, "tinlake-math/invalid-timestamp");
        require(chi != 0);
        // instead of a interestBearingAmount we use a accumulated interest rate index (chi)
        uint updatedChi = _chargeInterest(chi ,ratePerSecond, lastUpdated, block.timestamp);
        return (updatedChi, safeSub(rmul(updatedChi, pie), rmul(chi, pie)));
    }

    // @notice This function charge interest on a interestBearingAmount
    // @param interestBearingAmount is the interest bearing amount
    // @param ratePerSecond Interest rate accumulation per second in RAD(10ˆ27)
    // @param lastUpdated last time the interest has been charged
    // @return interestBearingAmount + interest
    function changeRatio(uint interestBearingAmount, uint ratePerSecond, uint lastUpdated) internal view returns (uint) {
        if (block.timestamp >= lastUpdated) {
            interestBearingAmount = _chargeInterest(interestBearingAmount, ratePerSecond, lastUpdated, block.timestamp);
        }
        return interestBearingAmount;
    }

    function _chargeInterest(uint interestBearingAmount, uint ratePerSecond, uint lastUpdated, uint current) internal pure returns (uint) {
        return rmul(rpow(ratePerSecond, current - lastUpdated, ONE), interestBearingAmount);
    }


    // convert pie to debt/savings amount
    function toAmount(uint chi, uint pie) private pure returns (uint) {
        return rmul(pie, chi);
    }

    // convert debt/savings amount to pie
    function toPie(uint chi, uint amount) private pure returns (uint) {
        return rdivup(amount, chi);
    }

    function rpow(uint x, uint n, uint base) private pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                let xx := mul(x, x)
                if iszero(eq(div(xx, x), x)) { revert(0,0) }
                let xxRound := add(xx, half)
                if lt(xxRound, xx) { revert(0,0) }
                x := div(xxRound, base)
                if mod(n,2) {
                    let zx := mul(z, x)
                    if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                    let zxRound := add(zx, half)
                    if lt(zxRound, zx) { revert(0,0) }
                    z := div(zxRound, base)
                }
            }
            }
        }
    }
}