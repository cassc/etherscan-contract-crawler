// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRouter {

  struct route {
    address from;
    address to;
    bool stable;
  }

  function swapExactTokensForTokens(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, route[] calldata routes, address to, uint deadline) external payable returns (uint[] memory amounts);
  function getAmountsOut(uint amountIn, route[] memory routes) external view returns (uint[] memory amounts);
}