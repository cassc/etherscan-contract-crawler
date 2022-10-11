// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/* ==========  Internal Libraries  ========== */
import "./FixedPoint.sol";
import "./UniswapV2OracleLibrary.sol";
import "../recipe/UniswapV2Library.sol";

library PriceLibrary {
    using FixedPoint for FixedPoint.uq112x112;
    using FixedPoint for FixedPoint.uq144x112;

    /* ========= Structs ========= */

    struct PriceObservation {
        uint32 timestamp;
        uint224 priceCumulativeLast;
        uint224 ethPriceCumulativeLast;
    }

    /**
     * @dev Average prices for a token in terms of weth and weth in terms of the token.
     *
     * Note: The average weth price is not equivalent to the reciprocal of the average
     * token price. See the UniSwap whitepaper for more info.
     */
    struct TwoWayAveragePrice {
        uint224 priceAverage;
        uint224 ethPriceAverage;
    }

    /* ========= View Functions ========= */

    function pairInitialized(
        address uniswapFactory,
        address token,
        address weth
    ) internal view returns (bool) {
        address pair = UniswapV2Library.pairFor(uniswapFactory, token, weth);
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair)
            .getReserves();
        return reserve0 != 0 && reserve1 != 0;
    }

    function observePrice(
        address uniswapFactory,
        address tokenIn,
        address quoteToken
    )
        internal
        view
        returns (
            uint32, /* timestamp */
            uint224 /* priceCumulativeLast */
        )
    {
        (address token0, address token1) = UniswapV2Library.sortTokens(
            tokenIn,
            quoteToken
        );
        address pair = UniswapV2Library.calculatePair(
            uniswapFactory,
            token0,
            token1
        );
        if (token0 == tokenIn) {
            (
                uint256 price0Cumulative,
                uint32 blockTimestamp
            ) = UniswapV2OracleLibrary.currentCumulativePrice0(pair);
            return (blockTimestamp, uint224(price0Cumulative));
        } else {
            (
                uint256 price1Cumulative,
                uint32 blockTimestamp
            ) = UniswapV2OracleLibrary.currentCumulativePrice1(pair);
            return (blockTimestamp, uint224(price1Cumulative));
        }
    }

    /**
     * @dev Query the current cumulative price of a token in terms of usdc
     * and the current cumulative price of usdc in terms of the token.
     */
    function observeTwoWayPrice(
        address uniswapFactory,
        address token,
        address usdc
    ) internal view returns (PriceObservation memory) {
        (address token0, address token1) = UniswapV2Library.sortTokens(
            token,
            usdc
        );
        address pair = UniswapV2Library.calculatePair(
            uniswapFactory,
            token0,
            token1
        );
        // Get the sorted token prices
        require(pair != address(0), "pair doesn't exist");

        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        // Check which token is weth and which is the token,
        // then build the price observation.
        if (token0 == token) {
            return
                PriceObservation({
                    timestamp: blockTimestamp,
                    priceCumulativeLast: uint224(price0Cumulative),
                    ethPriceCumulativeLast: uint224(price1Cumulative)
                });
        } else {
            return
                PriceObservation({
                    timestamp: blockTimestamp,
                    priceCumulativeLast: uint224(price1Cumulative),
                    ethPriceCumulativeLast: uint224(price0Cumulative)
                });
        }
    }

    /* ========= Utility Functions ========= */

    /**
     * @dev Computes the average price of a token in terms of weth
     * and the average price of weth in terms of a token using two
     * price observations.
     */
    function computeTwoWayAveragePrice(
        PriceObservation memory observation1,
        PriceObservation memory observation2
    ) internal pure returns (TwoWayAveragePrice memory) {
        uint32 timeElapsed = uint32(
            observation2.timestamp - observation1.timestamp
        );
        FixedPoint.uq112x112 memory priceAverage = UniswapV2OracleLibrary
            .computeAveragePrice(
                observation1.priceCumulativeLast,
                observation2.priceCumulativeLast,
                timeElapsed
            );
        FixedPoint.uq112x112 memory ethPriceAverage = UniswapV2OracleLibrary
            .computeAveragePrice(
                observation1.ethPriceCumulativeLast,
                observation2.ethPriceCumulativeLast,
                timeElapsed
            );
        return
            TwoWayAveragePrice({
                priceAverage: priceAverage._x,
                ethPriceAverage: ethPriceAverage._x
            });
    }

    function computeAveragePrice(
        uint32 timestampStart,
        uint224 priceCumulativeStart,
        uint32 timestampEnd,
        uint224 priceCumulativeEnd
    ) internal pure returns (FixedPoint.uq112x112 memory) {
        return
            UniswapV2OracleLibrary.computeAveragePrice(
                priceCumulativeStart,
                priceCumulativeEnd,
                uint32(timestampEnd - timestampStart)
            );
    }

    /**
     * @dev Computes the average price of the token the price observations
     * are for in terms of weth.
     */
    function computeAverageTokenPrice(
        PriceObservation memory observation1,
        PriceObservation memory observation2
    ) internal pure returns (FixedPoint.uq112x112 memory) {
        return
            UniswapV2OracleLibrary.computeAveragePrice(
                observation1.priceCumulativeLast,
                observation2.priceCumulativeLast,
                uint32(observation2.timestamp - observation1.timestamp)
            );
    }

    /**
     * @dev Computes the average price of weth in terms of the token
     * the price observations are for.
     */
    function computeAverageEthPrice(
        PriceObservation memory observation1,
        PriceObservation memory observation2
    ) internal pure returns (FixedPoint.uq112x112 memory) {
        return
            UniswapV2OracleLibrary.computeAveragePrice(
                observation1.ethPriceCumulativeLast,
                observation2.ethPriceCumulativeLast,
                uint32(observation2.timestamp - observation1.timestamp)
            );
    }

    /**
     * @dev Compute the average value in weth of `tokenAmount` of the
     * token that the average price values are for.
     */
    function computeAverageEthForTokens(
        TwoWayAveragePrice memory prices,
        uint256 tokenAmount
    ) internal pure returns (uint144) {
        return
            FixedPoint
                .uq112x112(prices.priceAverage)
                .mul(tokenAmount)
                .decode144();
    }

    /**
     * @dev Compute the average value of `wethAmount` weth in terms of
     * the token that the average price values are for.
     */
    function computeAverageTokensForEth(
        TwoWayAveragePrice memory prices,
        uint256 wethAmount
    ) internal pure returns (uint144) {
        return
            FixedPoint
                .uq112x112(prices.ethPriceAverage)
                .mul(wethAmount)
                .decode144();
    }
}