// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./INonfungiblePositionManager.sol";
import "./ISwapRouter.sol";

library Rebalance {
  using SafeERC20 for IERC20;

  struct Interval {
    int24 tickLower;
    int24 tickUpper;
    address positionManager;
    address liquidityRouter;
    uint256 tokenId;
  }

  event RebalanceCompleted(uint256 tokenId);

  function swap(
    address liquidityRouter,
    uint24 fee,
    address tokenIn,
    address tokenOut,
    uint256 amount
  ) internal {
    IERC20(tokenIn).safeApprove(liquidityRouter, amount);
    ISwapRouter(liquidityRouter).exactInputSingle(
      ISwapRouter.ExactInputSingleParams({
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fee: fee,
        recipient: address(this),
        amountIn: amount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      })
    );
    IERC20(tokenIn).safeApprove(liquidityRouter, 0);
  }

  function run(Interval memory interval, uint256 deadline) external returns (uint256 newTokenId) {
    INonfungiblePositionManager pm = INonfungiblePositionManager(interval.positionManager);
    if (interval.tokenId > 0) {
      (, , , , , , , uint128 liquidity, , , , ) = pm.positions(interval.tokenId);
      if (liquidity > 0) {
        pm.decreaseLiquidity(
          INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: interval.tokenId,
            liquidity: liquidity,
            amount0Min: 0,
            amount1Min: 0,
            deadline: deadline
          })
        );
      }
      pm.collect(
        INonfungiblePositionManager.CollectParams({
          tokenId: interval.tokenId,
          recipient: address(this),
          amount0Max: type(uint128).max,
          amount1Max: type(uint128).max
        })
      );
    }

    (, , address token0, address token1, uint24 fee, , , , , , , ) = pm.positions(interval.tokenId);
    uint256 amountIn1 = IERC20(token1).balanceOf(address(this));
    if (amountIn1 > 0) {
      swap(interval.liquidityRouter, fee, token1, token0, amountIn1);
    }
    swap(interval.liquidityRouter, fee, token0, token1, IERC20(token0).balanceOf(address(this)) / 2);

    uint256 balance0 = IERC20(token0).balanceOf(address(this));
    uint256 balance1 = IERC20(token1).balanceOf(address(this));
    IERC20(token0).safeApprove(address(pm), balance0);
    IERC20(token1).safeApprove(address(pm), balance1);
    (newTokenId, , , ) = pm.mint(
      INonfungiblePositionManager.MintParams({
        token0: token0,
        token1: token1,
        fee: fee,
        tickLower: interval.tickLower,
        tickUpper: interval.tickUpper,
        amount0Desired: balance0,
        amount1Desired: balance1,
        amount0Min: 0,
        amount1Min: 0,
        recipient: address(this),
        deadline: deadline
      })
    );
    IERC20(token0).safeApprove(address(pm), 0);
    IERC20(token1).safeApprove(address(pm), 0);
    emit RebalanceCompleted(newTokenId);
  }
}