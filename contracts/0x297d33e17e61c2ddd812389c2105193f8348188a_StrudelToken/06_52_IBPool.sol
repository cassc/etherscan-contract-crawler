// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

interface IBPool {
  function rebind(
    address token,
    uint256 balance,
    uint256 denorm
  ) external;

  function setSwapFee(uint256 swapFee) external;

  function setPublicSwap(bool publicSwap) external;

  function bind(
    address token,
    uint256 balance,
    uint256 denorm
  ) external;

  function unbind(address token) external;

  function gulp(address token) external;

  function isBound(address token) external view returns (bool);

  function getBalance(address token) external view returns (uint256);

  function getSwapFee() external view returns (uint256);

  function isPublicSwap() external view returns (bool);

  function getDenormalizedWeight(address token) external view returns (uint256);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);
}