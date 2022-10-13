/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "./Weather.sol";
import "../../../libraries/LibMath.sol";

/**
 * @title Sun
 **/
contract Sun is Weather {
    using Decimal for Decimal.D256;

    event SupplyIncrease(uint256 indexed season, uint256 price, uint256 newHarvestable, uint256 newSilo, int256 newSoil);
    event SupplyDecrease(uint256 indexed season, uint256 price, int256 newSoil);
    event SupplyNeutral(uint256 indexed season, int256 newSoil);

    /**
     * Internal
     **/

    // Sun

    function stepSun(Decimal.D256 memory topcornPrice, Decimal.D256 memory busdPrice) internal returns (uint256) {
        (uint256 bnb_reserve, uint256 topcorn_reserve) = lockedReserves();

        uint256 currentTopcorns = LibMath.sqrt((topcorn_reserve * (bnb_reserve) * 1e18) / (topcornPrice.mul(1e18).asUint256()));
        uint256 targetTopcorns = LibMath.sqrt((topcorn_reserve * (bnb_reserve) * 1e18) / (busdPrice.mul(1e18).asUint256()));

        uint256 price = topcornPrice.mul(1e18).div(busdPrice).asUint256();
        uint256 newSilo;

        if (currentTopcorns < targetTopcorns) {
            // > 1$
            newSilo = growSupply(targetTopcorns - currentTopcorns, price);
        } else if (currentTopcorns > targetTopcorns) {
            // < 1$
            shrinkSupply(currentTopcorns - targetTopcorns, price);
        } else {
            // == 1$
            int256 newSoil = setSoil(0);
            emit SupplyNeutral(season(), newSoil);
        }
        s.w.startSoil = s.f.soil;
        return newSilo;
    }

    function shrinkSupply(uint256 topcorns, uint256 price) private {
        int256 newSoil = setSoil(topcorns);
        emit SupplyDecrease(season(), price, newSoil);
    }

    function growSupply(uint256 topcorns, uint256 price) private returns (uint256) {
        (uint256 newHarvestable, uint256 newSilo) = increaseSupply(topcorns);
        int256 newSoil = setSoil(getMinSoil(newHarvestable));
        emit SupplyIncrease(season(), price, newHarvestable, newSilo, newSoil);
        return newSilo;
    }

    // (BNB, topcorns)
    function lockedReserves() public view returns (uint256, uint256) {
        (uint256 bnbReserve, uint256 topcornReserve) = reserves();
        uint256 lp = pair().totalSupply();
        if (lp == 0) return (0, 0);
        uint256 lockedLP = s.lp.deposited + s.lp.withdrawn;
        bnbReserve = (bnbReserve * lockedLP) / lp;
        topcornReserve = (topcornReserve * lockedLP) / lp;
        return (bnbReserve, topcornReserve);
    }
}