// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PeripheryLongChoice} from "@timeswap-labs/v2-periphery/contracts/enums/Transaction.sol";

struct TimeswapV2PeripheryUniswapV3CollectProtocolFeesParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address tokenTo;
  address excessLong0To;
  address excessLong1To;
  address excessShortTo;
  bool isToken0;
  uint256 long0Requested;
  uint256 long1Requested;
  uint256 shortRequested;
  uint256 minTokenAmount;
  uint256 minExcessLong0Amount;
  uint256 minExcessLong1Amount;
  uint256 minExcessShortAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3CollectTransactionFeesParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address tokenTo;
  address excessLong0To;
  address excessLong1To;
  address excessShortTo;
  bool isToken0;
  uint256 long0Requested;
  uint256 long1Requested;
  uint256 shortRequested;
  uint256 minTokenAmount;
  uint256 minExcessLong0Amount;
  uint256 minExcessLong1Amount;
  uint256 minExcessShortAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3CollectTransactionFeesAfterMaturityParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address to;
  bool isToken0;
  uint256 shortRequested;
  uint256 minTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3AddLiquidityGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address liquidityTo;
  address excessLong0To;
  address excessLong1To;
  address excessShortTo;
  bool isToken0;
  bool preferLong0Excess;
  uint256 tokenAmount;
  uint160 minLiquidityAmount;
  uint256 minExcessLong0Amount;
  uint256 minExcessLong1Amount;
  uint256 minExcessShortAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3RemoveLiquidityGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address tokenTo;
  address excessLong0To;
  address excessLong1To;
  address excessShortTo;
  bool isToken0;
  bool preferLong0Excess;
  uint160 liquidityAmount;
  uint256 minTokenAmount;
  uint256 minExcessLong0Amount;
  uint256 minExcessLong1Amount;
  uint256 minExcessShortAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3LendGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address to;
  bool isToken0;
  uint256 tokenAmount;
  uint256 minReturnAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3LendGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address to;
  bool isToken0;
  uint256 positionAmount;
  uint256 maxTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3CloseBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address to;
  bool isToken0;
  bool isLong0;
  uint256 positionAmount;
  uint256 maxTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3BorrowGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address tokenTo;
  address longTo;
  bool isToken0;
  bool isLong0;
  uint256 tokenAmount;
  uint256 maxPositionAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3BorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address tokenTo;
  address longTo;
  bool isToken0;
  bool isLong0;
  uint256 positionAmount;
  uint256 minTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3CloseLendGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address to;
  bool isToken0;
  uint256 positionAmount;
  uint256 minTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3RedeemParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address to;
  bool isToken0;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  uint256 minTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3TransformParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address tokenTo;
  address longTo;
  bool isToken0;
  bool isLong0ToLong1;
  uint256 positionAmount;
  bool isMaxTokenDeposit;
  uint256 minOrMaxTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3WithdrawParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address to;
  bool isToken0;
  uint256 positionAmount;
  uint256 minTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryUniswapV3RebalanceParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  uint24 uniswapV3Fee;
  address tokenTo;
  address excessShortTo;
  bool isToken0;
  uint256 minTokenAmount;
  uint256 minExcessShortAmount;
  uint256 deadline;
}