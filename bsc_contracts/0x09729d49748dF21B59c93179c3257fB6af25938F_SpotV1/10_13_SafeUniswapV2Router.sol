// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";

library SafeUniswapV2Router {
  using SafeERC20 for IERC20;

  function safeSwapExactTokensForTokens(
    IUniswapV2Router router,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) internal returns (uint256[] memory amounts) {
    if (path[0] != path[path.length - 1])
      amounts = router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
  }

  function addAllLiquidity(
    IUniswapV2Router router,
    address tokenA,
    address tokenB,
    address to,
    uint256 deadline
  )
    internal
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 amountA = IERC20(tokenA).balanceOf(address(this));
    if (IERC20(tokenA).allowance(address(this), address(router)) > 0) {
      IERC20(tokenA).safeApprove(address(router), 0);
    }
    IERC20(tokenA).safeApprove(address(router), amountA);

    uint256 amountB = IERC20(tokenB).balanceOf(address(this));
    if (IERC20(tokenB).allowance(address(this), address(router)) > 0) {
      IERC20(tokenB).safeApprove(address(router), 0);
    }
    IERC20(tokenB).safeApprove(address(router), amountB);

    return router.addLiquidity(tokenA, tokenB, amountA, amountB, 0, 0, to, deadline);
  }

  function removeAllLiquidity(
    IUniswapV2Router router,
    address pair,
    address to,
    uint256 deadline
  )
    internal
    returns (
      address tokenA,
      address tokenB,
      uint256 amountA,
      uint256 amountB
    )
  {
    tokenA = IUniswapV2Pair(pair).token0();
    tokenB = IUniswapV2Pair(pair).token1();

    uint256 balance = IERC20(pair).balanceOf(address(this));
    if (IERC20(pair).allowance(address(this), address(router)) > 0) {
      IERC20(pair).safeApprove(address(router), 0);
    }
    IERC20(pair).safeApprove(address(router), balance);

    (amountA, amountB) = router.removeLiquidity(tokenA, tokenB, balance, 0, 0, to, deadline);
  }
}