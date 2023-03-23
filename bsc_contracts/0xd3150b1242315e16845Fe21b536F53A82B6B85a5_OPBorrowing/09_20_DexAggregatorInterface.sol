// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface DexAggregatorInterface {
    function getPrice(address desToken, address quoteToken, bytes memory data) external view returns (uint256 price, uint8 decimals);

    function getPriceCAvgPriceHAvgPrice(
        address desToken,
        address quoteToken,
        uint32 secondsAgo,
        bytes memory dexData
    ) external view returns (uint256 price, uint256 cAvgPrice, uint256 hAvgPrice, uint8 decimals, uint256 timestamp);

    function updatePriceOracle(address desToken, address quoteToken, uint32 timeWindow, bytes memory data) external returns (bool);

    function getToken0Liquidity(address token0, address token1, bytes memory dexData) external view returns (uint);

    function getPairLiquidity(address token0, address token1, bytes memory dexData) external view returns (uint token0Liq, uint token1Liq);

    function buy(
        address buyToken,
        address sellToken,
        uint24 buyTax,
        uint24 sellTax,
        uint buyAmount,
        uint maxSellAmount,
        bytes memory data
    ) external returns (uint sellAmount);

    function sell(address buyToken, address sellToken, uint sellAmount, uint minBuyAmount, bytes memory data) external returns (uint buyAmount);
}