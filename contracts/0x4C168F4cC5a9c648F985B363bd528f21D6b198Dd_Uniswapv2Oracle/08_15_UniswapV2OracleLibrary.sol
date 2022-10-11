// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/* ==========  Internal Interfaces  ========== */
import "../interfaces/IUniswapV2Pair.sol";

/* ==========  Internal Libraries  ========== */
import "./FixedPoint.sol";

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2OracleLibrary.sol
This source code has been modified from the original, which was copied from the github repository
at commit hash 6d03bede0a97c72323fa1c379ed3fdf7231d0b26.
Subject to the GPL-3.0 license
*************************************************************************************************/

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // produces the cumulative prices using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        require(
            reserve0 != 0 && reserve1 != 0,
            "UniswapV2OracleLibrary::currentCumulativePrices: Pair has no reserves."
        );
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += (uint256(
                FixedPoint.fraction(reserve1, reserve0)._x
            ) * timeElapsed);
            // counterfactual
            price1Cumulative += (uint256(
                FixedPoint.fraction(reserve0, reserve1)._x
            ) * timeElapsed);
        }
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    // only gets the first price
    function currentCumulativePrice0(address pair)
        internal
        view
        returns (uint256 price0Cumulative, uint32 blockTimestamp)
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        require(
            reserve0 != 0 && reserve1 != 0,
            "UniswapV2OracleLibrary::currentCumulativePrice0: Pair has no reserves."
        );
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += (uint256(
                FixedPoint.fraction(reserve1, reserve0)._x
            ) * timeElapsed);
        }
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    // only gets the second price
    function currentCumulativePrice1(address pair)
        internal
        view
        returns (uint256 price1Cumulative, uint32 blockTimestamp)
    {
        blockTimestamp = currentBlockTimestamp();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        require(
            reserve0 != 0 && reserve1 != 0,
            "UniswapV2OracleLibrary::currentCumulativePrice1: Pair has no reserves."
        );
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price1Cumulative += (uint256(
                FixedPoint.fraction(reserve0, reserve1)._x
            ) * timeElapsed);
        }
    }

    function computeAveragePrice(
        uint224 priceCumulativeStart,
        uint224 priceCumulativeEnd,
        uint32 timeElapsed
    ) internal pure returns (FixedPoint.uq112x112 memory priceAverage) {
        // overflow is desired.
        priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
    }
}