pragma solidity >=0.8.13;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    /// @dev produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint price0Cumulative,
            uint price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = uint32(block.timestamp);
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            unchecked {
                // subtraction overflow is desired
                uint32 timeElapsed = blockTimestamp - blockTimestampLast;
                // addition overflow is desired
                // counterfactual
                price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
                // counterfactual
                price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
            }
        }
    }
}