// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol";

contract ExposedV3Math {

  /* 
    TickMath.sol exposed functions
  */
  function getSqrtRatioAtTick(int24 tick) external pure returns (uint160 sqrtPriceX96) {
    return TickMath.getSqrtRatioAtTick(tick);
  }

  function getTickAtSqrtRatio(uint160 sqrtPriceX96) external pure returns (int24 tick) {
    return TickMath.getTickAtSqrtRatio(sqrtPriceX96);
  }

  /* 
    SqrtPriceMath.sol exposed functions
  */

  function getNextSqrtPriceFromAmount0RoundingUp(
    uint160 sqrtPX96,
    uint128 liquidity,
    uint256 amount,
    bool add
  ) external pure returns (uint160) {
    return SqrtPriceMath.getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amount, add);
  }

  function getNextSqrtPriceFromAmount1RoundingDown(
    uint160 sqrtPX96,
    uint128 liquidity,
    uint256 amount,
    bool add
  ) external pure returns (uint160) {
    return SqrtPriceMath.getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amount, add);
  }

  function getNextSqrtPriceFromInput(
    uint160 sqrtPX96,
    uint128 liquidity,
    uint256 amountIn,
    bool zeroForOne
  ) external pure returns (uint160 sqrtQX96) {
    return SqrtPriceMath.getNextSqrtPriceFromInput(sqrtPX96, liquidity, amountIn, zeroForOne);
  }

  function getNextSqrtPriceFromOutput(
    uint160 sqrtPX96,
    uint128 liquidity,
    uint256 amountOut,
    bool zeroForOne
  ) external pure returns (uint160 sqrtQX96) {
    return SqrtPriceMath.getNextSqrtPriceFromOutput(sqrtPX96, liquidity, amountOut, zeroForOne);
  }

  function getAmount0Delta(
      uint160 sqrtRatioAX96,
      uint160 sqrtRatioBX96,
      uint128 liquidity,
      bool roundUp
  ) external pure returns (uint256 amount0) {
    return SqrtPriceMath.getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, liquidity, roundUp);
  }

  function getAmount1Delta(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint128 liquidity,
    bool roundUp
  ) external pure returns (uint256 amount1) {
    return SqrtPriceMath.getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, liquidity, roundUp);
  }

  function getAmount0Delta(
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    int128 liquidity
  ) external pure returns (int256 amount0) {
    return SqrtPriceMath.getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, liquidity);
  }

  function getAmount1Delta(
      uint160 sqrtRatioAX96,
      uint160 sqrtRatioBX96,
      int128 liquidity
  ) external pure returns (int256 amount1) {
    return SqrtPriceMath.getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, liquidity);
  }

}