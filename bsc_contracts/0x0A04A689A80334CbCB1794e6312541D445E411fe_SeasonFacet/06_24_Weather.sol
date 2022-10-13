/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../../../libraries/Decimal.sol";
import "../../../libraries/LibMarket.sol";
import "../../../libraries/LibMath.sol";
import "./Silo.sol";

/**
 * @title Weather
 **/
contract Weather is Silo {
    using Decimal for Decimal.D256;

    event WeatherChange(uint256 indexed season, uint256 caseId, int8 change, uint32 currentYield);
    event SeasonOfPlenty(uint256 indexed season, uint256 bnb, uint256 harvestable);
    event PodRateSnapshot(uint256 indexed season, uint256 podRate);

    /**
     * Getters
     **/

    // Weather

    function weather() external view returns (Storage.Weather memory) {
        return s.w;
    }

    function rain() external view returns (Storage.Rain memory) {
        return s.r;
    }

    function yield() public view returns (uint32) {
        return s.w.yield;
    }

    // Reserves

    // (BNB, topcorns)
    function reserves() public view returns (uint256, uint256) {
        (uint112 reserve0, uint112 reserve1, ) = pair().getReserves();
        return s.index == 0 ? (reserve1, reserve0) : (reserve0, reserve1);
    }

    // (BNB, BUSD)
    function pegReserves() public view returns (uint256, uint256) {
        (uint112 reserve0, uint112 reserve1, ) = pegPair().getReserves();
        return s.pegIndex == 0 ? (reserve1, reserve0) : (reserve0, reserve1);
    }

    /**
     * Internal
     **/

    function stepWeather(uint256 int_price, uint256 endSoil) internal {
        if (topcorn().totalSupply() == 0) {
            s.w.yield = 1;
            return;
        }

        // Calculate Pod Rate
        Decimal.D256 memory podRate = Decimal.ratio(s.f.pods - s.f.harvestable, topcorn().totalSupply());

        // Calculate Delta Soil Demand
        uint256 dsoil = s.w.startSoil - endSoil;

        Decimal.D256 memory deltaPodDemand;

        // If Sow'd all Soil
        if (s.w.nextSowTime < type(uint32).max) {
            if (
                s.w.lastSowTime == type(uint32).max || // Didn't Sow all last Season
                s.w.nextSowTime < 300 || // Sow'd all instantly this Season
                (s.w.lastSowTime > C.getSteadySowTime() && s.w.nextSowTime < s.w.lastSowTime - C.getSteadySowTime()) // Sow'd all faster
            ) deltaPodDemand = Decimal.from(1e18);
            else if (s.w.nextSowTime <= s.w.lastSowTime + C.getSteadySowTime())
                // Sow'd all in same time
                deltaPodDemand = Decimal.one();
            else deltaPodDemand = Decimal.zero();
            s.w.lastSowTime = s.w.nextSowTime;
            s.w.nextSowTime = type(uint32).max;
            // If soil didn't sell out
        } else {
            uint256 lastDSoil = s.w.lastDSoil;
            if (dsoil == 0)
                deltaPodDemand = Decimal.zero(); // If no one sow'd
            else if (lastDSoil == 0)
                deltaPodDemand = Decimal.from(1e18); // If no one sow'd last Season
            else deltaPodDemand = Decimal.ratio(dsoil, lastDSoil);
            if (s.w.lastSowTime != type(uint32).max) s.w.lastSowTime = type(uint32).max;
        }

        // Calculate Weather Case
        uint8 caseId = 0;

        // Evaluate Pod Rate
        if (podRate.greaterThanOrEqualTo(C.getUpperBoundPodRate())) caseId = 24;
        else if (podRate.greaterThanOrEqualTo(C.getOptimalPodRate())) caseId = 16;
        else if (podRate.greaterThanOrEqualTo(C.getLowerBoundPodRate())) caseId = 8;

        // Evaluate Price
        if (int_price > 1e18 || (int_price == 1e18 && podRate.lessThanOrEqualTo(C.getOptimalPodRate()))) caseId += 4;

        // Evaluate Delta Soil Demand
        if (deltaPodDemand.greaterThanOrEqualTo(C.getUpperBoundDPD())) caseId += 2;
        else if (deltaPodDemand.greaterThanOrEqualTo(C.getLowerBoundDPD())) caseId += 1;

        s.w.lastDSoil = dsoil;

        emit PodRateSnapshot(season(), podRate.mul(1e18).asUint256());
        changeWeather(caseId);
        handleRain(caseId);
    }

    function changeWeather(uint256 caseId) private {
        int8 change = s.cases[caseId];
        if (change < 0) {
            if (yield() <= (uint32(uint8(-change)))) {
                // if (change < 0 && yield() <= uint32(-change)),
                // then 0 <= yield() <= type(int8).max because change is an int8.
                // Thus, downcasting yield() to an int8 will not cause overflow.
                change = 1 - int8(int32(yield()));
                s.w.yield = 1;
            } else s.w.yield = yield() - (uint32(uint8(-change)));
        }
        if (change > 0) {
            s.w.yield = yield() + (uint32(uint8(change)));
        }

        emit WeatherChange(season(), caseId, change, s.w.yield);
    }

    function handleRain(uint256 caseId) internal {
        if (caseId < 4 || caseId > 7) {
            if (s.r.raining) s.r.raining = false;
            return;
        } else if (!s.r.raining) {
            s.r.raining = true;
            s.sops[season()] = s.sops[s.r.start];
            s.r.start = season();
            s.r.pods = s.f.pods;
            s.r.roots = s.s.roots;
        } else if (season() >= s.r.start + (s.season.withdrawSeasons - 1)) {
            if (s.r.roots > 0) sop();
        }
    }

    function sop() private {
        (uint256 newTopcorns, uint256 newBNB) = calculateSopTopcornsAndBNB();
        if (newBNB <= s.s.roots / 1e32 || (s.sop.base > 0 && (newTopcorns * s.sop.base) / s.sop.wbnb / s.r.roots == 0)) return;

        mintToSilo(newTopcorns);
        uint256 bnbBought = LibMarket.sellToWBNB(newTopcorns, 0);
        uint256 newHarvestable = 0;
        if (s.f.harvestable < s.r.pods) {
            newHarvestable = s.r.pods - s.f.harvestable;
            mintToHarvestable(newHarvestable);
        }
        if (bnbBought == 0) return;
        rewardBNB(bnbBought);
        emit SeasonOfPlenty(season(), bnbBought, newHarvestable);
    }

    function calculateSopTopcornsAndBNB() private view returns (uint256, uint256) {
        (uint256 bnbTopcornPool, uint256 topcornsTopcornPool) = reserves();
        (uint256 bnbBUSDPool, uint256 busdBUSDPool) = pegReserves();

        uint256 newTopcorns = LibMath.sqrt((bnbTopcornPool * topcornsTopcornPool * busdBUSDPool) / bnbBUSDPool);
        if (newTopcorns <= topcornsTopcornPool) return (0, 0);
        uint256 topcorns = newTopcorns - topcornsTopcornPool;
        topcorns = (topcorns * 100000) / 99875 + 1;

        uint256 topcornsWithFee = topcorns * 9975;
        uint256 numerator = topcornsWithFee * bnbTopcornPool;
        uint256 denominator = topcornsTopcornPool * 10000 + topcornsWithFee;
        uint256 bnb = numerator / denominator;

        return (topcorns, bnb);
    }
}