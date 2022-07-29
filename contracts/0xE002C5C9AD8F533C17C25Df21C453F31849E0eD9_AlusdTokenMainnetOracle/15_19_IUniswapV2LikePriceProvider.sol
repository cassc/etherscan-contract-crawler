// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./IPriceProvider.sol";

interface IUniswapV2LikePriceProvider is IPriceProvider {
    /**
     * @notice The default time-weighted average price (TWAP) period
     * Used when a period isn't specified
     * @dev See more: https://docs.uniswap.org/protocol/concepts/V3-overview/oracle
     */
    function defaultTwapPeriod() external view returns (uint256);

    /**
     * @notice Check if there is an oracle for the PAIR-TWAP key
     * @param pair_ The pair
     * @param twapPeriod_ The TWAP period
     * @return True if exists
     */
    function hasOracle(IUniswapV2Pair pair_, uint256 twapPeriod_) external view returns (bool);

    /**
     * @notice Check if there is an oracle for the PAIR-TWAP key
     * @dev Uses `defaultTwapPeriod`
     * @param pair_ The pair
     * @return True if exists
     */
    function hasOracle(IUniswapV2Pair pair_) external view returns (bool);

    /**
     * @notice Returns the pair's contract
     */
    function pairFor(address token0_, address token1_) external view returns (IUniswapV2Pair _pair);

    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param token_ The address of assetIn
     * @param twapPeriod_ The TWAP period
     * @return _priceInUsd The USD price
     * @return _lastUpdatedAt Last updated timestamp
     */
    function getPriceInUsd(address token_, uint256 twapPeriod_)
        external
        view
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param twapPeriod_ The TWAP period
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote in USD (or equivalent) amount
     * @param token_ The address of assetIn
     * @param amountIn_ Amount of input token.
     * @return amountOut_ Amount in USD
     * @param twapPeriod_ The TWAP period
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quoteTokenToUsd(
        address token_,
        uint256 amountIn_,
        uint256 twapPeriod_
    ) external view returns (uint256 amountOut_, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote from USD (or equivalent) amount to amount of token
     * @param token_ The address of assetIn
     * @param amountIn_ Input amount in USD
     * @param twapPeriod_ The TWAP period
     * @return _amountOut Output amount of token
     * @return _lastUpdatedAt Last updated timestamp
     */
    function quoteUsdToToken(
        address token_,
        uint256 amountIn_,
        uint256 twapPeriod_
    ) external view returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote
     * @dev Will update the oracle if needed before getting quote
     * @dev Uses `defaultTwapPeriod`
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _lastUpdatedAt Last updated timestamp
     */
    function updateAndQuote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Get quote
     * @dev Will update the oracle if needed before getting quote
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param twapPeriod_ The TWAP period
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _lastUpdatedAt Last updated timestamp
     */
    function updateAndQuote(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_,
        uint256 amountIn_
    ) external returns (uint256 _amountOut, uint256 _lastUpdatedAt);

    /**
     * @notice Update the default TWAP period
     * @dev Administrative function
     * @param newDefaultTwapPeriod_ The new default period
     */
    function updateDefaultTwapPeriod(uint256 newDefaultTwapPeriod_) external;

    /**
     * @notice Update cumulative and average price of pair
     * @dev Will create the pair if it doesn't exist
     * @dev Uses `defaultTwapPeriod`
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     */
    function updateOrAdd(address tokenIn_, address tokenOut_) external;

    /**
     * @notice Update cumulative and average price of pair
     * @dev Will create the pair if it doesn't exist
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param twapPeriod_ The TWAP period
     */
    function updateOrAdd(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_
    ) external;
}