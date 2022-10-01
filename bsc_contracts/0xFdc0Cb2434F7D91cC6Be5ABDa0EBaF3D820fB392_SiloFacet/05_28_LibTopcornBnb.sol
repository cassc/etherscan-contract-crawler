/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "./LibAppStorage.sol";
import "./PancakeOracleLibrary.sol";
import "./LibMath.sol";
import "./Decimal.sol";

/**
 * @title Lib TopCorn BNB V2 Silo
 **/
library LibTopcornBnb {
    using Decimal for Decimal.D256;

    uint256 private constant TWO_TO_THE_112 = 2**112;

    function lpToLPTopcorns(uint256 amount) internal view returns (uint256 topcorns) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        (uint112 reserve0, uint112 reserve1, uint32 lastTimestamp) = IPancakePair(s.c.pair).getReserves();

        uint256 topcornReserve;

        // Check the last timestamp in the Pancake Pair to see if anyone has interacted with the pair this block.
        // If so, use current Season TWAP to calculate TopCorn Reserves for flash loan protection
        // If not, we can use the current reserves with the assurance that there is no active flash loan
        if (lastTimestamp == uint32(block.timestamp % 2**32)) topcornReserve = twapTopcornReserve(reserve0, reserve1, lastTimestamp);
        else topcornReserve = s.index == 0 ? reserve0 : reserve1;
        topcorns = (amount * topcornReserve * 2) / (IPancakePair(s.c.pair).totalSupply());
    }

    function twapTopcornReserve(
        uint112 reserve0,
        uint112 reserve1,
        uint32 lastTimestamp
    ) internal view returns (uint256 topcorns) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = PancakeOracleLibrary.currentCumulativePricesWithReserves(s.c.pair, reserve0, reserve1, lastTimestamp);
        uint256 priceCumulative = s.index == 0 ? price0Cumulative : price1Cumulative;
        uint32 deltaTimestamp = uint32(blockTimestamp - s.o.timestamp);
        require(deltaTimestamp > 0, "Silo: Oracle same Season");
        uint256 price = (priceCumulative - s.o.cumulative) / deltaTimestamp;
        price = Decimal.ratio(price, TWO_TO_THE_112).mul(1e18).asUint256();
        topcorns = LibMath.sqrt((uint256(reserve0) * (uint256(reserve1))) / price);
    }
}