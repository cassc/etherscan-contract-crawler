// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IRouter {
  struct Route {
    address from;
    address to;
    bool stable;
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external;

  function quoteAddLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint256 amountADesired,
    uint256 amountBDesired
  )
    external
    view
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    Route[] calldata routes,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactTokensForTokensSimple(
    uint256 amountIn,
    uint256 amountOutMin,
    address tokenFrom,
    address tokenTo,
    bool stable,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function getAmountOut(
    uint256 amountIn,
    address tokenIn,
    address tokenOut
  ) external view returns (uint256 amount, bool stable);

  function getAmountsOut(uint256 amountIn, Route[] memory routes) external view returns (uint256[] memory amounts);

  function getReserves(
    address tokenA,
    address tokenB,
    bool stable
  ) external view returns (uint256 reserveA, uint256 reserveB);

  function swapExactMATICForTokens(
    uint256 amountOutMin,
    Route[] calldata routes,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);
}