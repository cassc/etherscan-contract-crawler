// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

struct UniswapV3SwapParam {
  address recipient;
  bool zeroForOne;
  bool exactInput;
  uint256 amount;
  uint256 strikeLimit;
  bytes data;
}

struct UniswapV3SwapForRebalanceParam {
  address recipient;
  bool zeroForOne;
  bool exactInput;
  uint256 amount;
  uint256 strikeLimit;
  uint256 transactionFee;
  bytes data;
}

struct UniswapV3CalculateSwapParam {
  bool zeroForOne;
  bool exactInput;
  uint256 amount;
  uint256 strikeLimit;
  bytes data;
}

struct UniswapV3CalculateSwapGivenBalanceLimitParam {
  address token0;
  address token1;
  uint256 strike;
  uint24 uniswapV3Fee;
  bool isToken0;
  uint256 token0Balance;
  uint256 token1Balance;
  uint256 tokenAmount;
}

struct UniswapV3CalculateSwapForRebalanceParam {
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 strikeLimit;
  uint256 transactionFee;
  bytes data;
}

struct UniswapV3SwapCalculationParam {
  uint24 uniswapV3Fee;
  uint160 sqrtPriceX96;
  uint160 sqrtRatioTargetX96;
  int24 tick;
  int256 amountSpecified;
  bool zeroForOne;
  bool exactInput;
}