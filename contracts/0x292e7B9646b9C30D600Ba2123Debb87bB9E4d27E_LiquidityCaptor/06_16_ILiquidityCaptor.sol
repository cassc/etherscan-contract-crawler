// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILiquidityCaptor {
  function captureLiquidity(uint256 bluAmountIn, uint256 minReserveAmountOut)
    external
    returns (uint256 amountOut, uint256 liquidity);

  function setMaxDiscount(uint256 _maxDiscount) external;

  function setPeriod(uint256 _period) external;

  function setMinPrice(uint256 _minPrice) external;

  function getReserves()
    external
    view
    returns (uint256 bluReserve, uint256 reserveReserve);

  event LiquidityCaptured(
    uint256 bluAmount,
    uint256 reserveAmount,
    uint256 liquidity
  );
}