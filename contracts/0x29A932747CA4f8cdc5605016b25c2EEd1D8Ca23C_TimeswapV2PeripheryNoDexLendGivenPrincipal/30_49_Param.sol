pragma solidity =0.8.8;

struct TimeswapV2PeripheryNoDexLendGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  uint256 tokenAmount;
  uint256 minReturnAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexBorrowGivenPrincipalParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isToken0;
  bool isLong0;
  uint256 tokenAmount;
  uint256 maxPositionAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexBorrowGivenPositionParam {
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

struct TimeswapV2PeripheryNoDexCloseBorrowGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  bool isLong0;
  uint256 positionAmount;
  uint256 maxTokenAmount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexCloseLendGivenPositionParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  bool isToken0;
  uint256 positionAmount;
  uint256 minToken0Amount;
  uint256 minToken1Amount;
  uint256 deadline;
}

struct TimeswapV2PeripheryNoDexWithdrawParam {
  address token0;
  address token1;
  uint256 strike;
  uint256 maturity;
  address to;
  uint256 positionAmount;
  uint256 minToken0Amount;
  uint256 minToken1Amount;
  uint256 deadline;
}