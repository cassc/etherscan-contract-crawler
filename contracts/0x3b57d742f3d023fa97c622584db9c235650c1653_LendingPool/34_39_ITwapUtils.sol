// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ITwapUtils {
  function twapInterval() external view returns (uint32);

  function getPoolPriceUSDX96(
    address priceToken,
    address pricePool,
    address nativeStablePool,
    address WETH9,
    bool isPoolPairedWETH9
  ) external view returns (uint256);

  function getSqrtPriceX96FromPoolAndInterval(
    address uniswapV3Pool
  ) external view returns (uint160 sqrtPriceX96);

  function getSqrtPriceX96FromPriceX96(
    uint256 priceX96
  ) external pure returns (uint160 sqrtPriceX96);

  function getPriceX96FromSqrtPriceX96(
    uint160 sqrtPriceX96
  ) external pure returns (uint256 priceX96);
}