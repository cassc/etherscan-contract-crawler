// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

struct TimeswapV2PeripheryCollectProtocolFeesExcessLongChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Balance;
  uint256 token1Balance;
  uint256 tokenAmount;
  bytes data;
}

struct TimeswapV2PeripheryCollectTransactionFeesExcessLongChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Balance;
  uint256 token1Balance;
  uint256 tokenAmount;
  bytes data;
}

struct TimeswapV2PeripheryAddLiquidityGivenPrincipalInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 liquidityAmount;
  uint256 excessLong0Amount;
  uint256 excessLong1Amount;
  uint256 excessShortAmount;
  bytes data;
}

struct TimeswapV2PeripheryRemoveLiquidityGivenPositionChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Balance;
  uint256 token1Balance;
  uint256 tokenAmount;
  bytes data;
}

struct TimeswapV2PeripheryLendGivenPrincipalInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 positionAmount;
  bytes data;
}

struct TimeswapV2PeripheryCloseBorrowGivenPositionChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0;
  uint256 tokenAmount;
  bytes data;
}

struct TimeswapV2PeripheryCloseBorrowGivenPositionInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 positionAmount;
  bytes data;
}

struct TimeswapV2PeripheryBorrowGivenPrincipalInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 positionAmount;
  bytes data;
}

struct TimeswapV2PeripheryBorrowGivenPositionChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0;
  uint256 token0Balance;
  uint256 token1Balance;
  uint256 tokenAmount;
  bytes data;
}

struct TimeswapV2PeripheryBorrowGivenPositionInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 positionAmount;
  bytes data;
}

struct TimeswapV2PeripheryCloseLendGivenPositionChoiceInternalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint256 token0Balance;
  uint256 token1Balance;
  uint256 tokenAmount;
  bytes data;
}

struct TimeswapV2PeripheryTransformInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  bytes data;
}

struct TimeswapV2PeripheryRebalanceInternalParam {
  address optionPair;
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 excessShortAmount;
  bytes data;
}