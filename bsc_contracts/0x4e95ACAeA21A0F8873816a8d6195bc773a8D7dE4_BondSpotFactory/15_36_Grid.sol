// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Grid {
    enum GridType {
        Artithmetic,
        Geometric
    }

    struct GridOrderData {
        uint128 pip;
        // negative is sell
        // positive is buy
        int256 amount;
    }

    // @dev generate grid base on the GridType
    function generateGrid(
        uint256 currentPip,
        uint80 lowerLimit,
        uint80 upperLimit,
        uint16 gridCount,
        uint128 baseAmount,
        uint128 quoteAmount
    ) internal pure returns (GridOrderData[] memory out) {
        (
            uint256[] memory priceGrids,
            uint256 bidCount,
            uint256 askCount
        ) = generateGridArithmeticPrice(
                currentPip,
                lowerLimit,
                upperLimit,
                gridCount
            );
        out = new GridOrderData[](priceGrids.length);
        int256 gridBidQty;
        int256 gridAskQty;
        // bidCount must > 0
        if (bidCount > 0) {
            gridBidQty = -int256(uint256(quoteAmount / uint128(bidCount)));
        }
        if (askCount > 0) {
            gridAskQty = int256(uint256(baseAmount / uint128(askCount)));
        }
        for (uint256 i = 0; i < priceGrids.length; i++) {
            out[i] = GridOrderData({
                pip: uint128(priceGrids[i]),
                amount: priceGrids[i] <= currentPip ? gridBidQty : gridAskQty
            });
        }
    }

    //Arithmetic: Each grid has an equal price difference.
    //The arithmetic grid divides the price range from grid_lower_limit to grid_upper_limit into grid_count by equal price difference.
    function generateGridArithmeticPrice(
        uint256 currentPip,
        uint80 lowerLimit,
        uint80 upperLimit,
        uint16 gridCount
    )
        internal
        pure
        returns (
            uint256[] memory result,
            uint256 bidCount,
            uint256 askCount
        )
    {
        result = new uint256[](gridCount);
        uint80 step = (upperLimit - lowerLimit) / uint80(gridCount);
        for (uint80 i = 0; i < uint80(gridCount); i++) {
            uint256 _p = uint256(lowerLimit + i * step);
            if (_p <= currentPip) {
                bidCount++;
            } else {
                askCount++;
            }
            result[i] = _p;
        }
    }

    // Geometric: Each grid has an equal price difference ratio.
    // The geometric grid divides the price range from grid_lower_limit to grid_upper_limit by into grid_count by equal price ratio.
    // Example: Geometric grid price_diff_percentage = 10%: 1000, 1100, 1210, 1331, 1464.1,... (the next price is 10% higher than the previous one)
    function generateGridGeometricPrice(
        uint256 currentPip,
        uint256 lowerLimit,
        uint256 upperLimit,
        uint256 gridCount
    )
        internal
        pure
        returns (
            uint256[] memory result,
            uint256 bidCount,
            uint256 askCount
        )
    {
        uint256 price_ratio = (upperLimit / lowerLimit)**(1 / gridCount); // TODO resolve 1/gridCount
        /**
        Geometric: Each grid has an equal price difference ratio.
        The geometric grid divides the price range from grid_lower_limit to grid_upper_limit by into grid_count by equal price ratio.
        The price ratio of each grid is:
        price_ratio = (grid_upper_limit / grid_lower_limit)^(1/grid_count)
        The price difference of each grid is:
        price_diff_percentage = ( (grid_upper_limit / grid_lower_limit) ^ (1/grid_count) - 1)*100%
        Then it constructed a series of price intervals:
        price_1 = grid_lower_limit
        price_2 = grid_lower_limit* price_ratio
        price_3 = grid_lower_limit * price_ratio ^ 2
        ...
        price_n = grid_lower_limit* price_ratio ^ (n-1)
        At grid_upper_limit，n = grid_count
        Example: Geometric grid price_diff_percentage = 10%: 1000, 1100, 1210, 1331, 1464.1,... (the next price is 10% higher than the previous one)

        Reference: https://www.binance.com/en/support/faq/f4c453bab89648beb722aa26634120c3
         */
    }
}