// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ISwapRouter.sol";

library StopLoss {
  using SafeERC20 for IERC20;

  struct Order {
    address[] path;
    uint24 fee;
    uint256 amountOut;
    uint256 amountOutMin;
  }

  event StopLossOrderCompleted(uint256 amountOut);

  function run(
    Order storage order,
    address liquidityRouter,
    address[] memory inTokens
  ) internal {
    require(order.path.length > 1 && order.amountOut > 0, "StopLoss::run: stop loss disabled");
    require(inTokens.length <= 256, "StopLoss::run: too many tokens");
    for (uint8 i = 0; i < inTokens.length; i++) {
      address token = inTokens[i];
      if (token == order.path[0]) continue;
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (balance == 0) continue;
      IERC20(token).safeApprove(liquidityRouter, balance);
      ISwapRouter(liquidityRouter).exactInputSingle(
        ISwapRouter.ExactInputSingleParams({
          tokenIn: token,
          tokenOut: order.path[0],
          fee: order.fee,
          recipient: address(this),
          amountIn: balance,
          amountOutMinimum: 0,
          sqrtPriceLimitX96: 0
        })
      );
      IERC20(token).safeApprove(liquidityRouter, 0);
    }

    address baseToken = order.path[0];
    uint256 baseBalance = IERC20(baseToken).balanceOf(address(this));
    uint256 amountOut = baseBalance;
    if (baseToken != order.path[order.path.length - 1]) {
      require(baseBalance > 0, "StopLoss::run: insufficient balance of base token");
      IERC20(baseToken).safeApprove(liquidityRouter, baseBalance);
      bytes memory pathBytes = abi.encodePacked(order.path[0]);
      for (uint256 i = 1; i < order.path.length; i++) {
        pathBytes = bytes.concat(pathBytes, abi.encodePacked(uint24(order.fee), order.path[i]));
      }
      amountOut = ISwapRouter(liquidityRouter).exactInput(
        ISwapRouter.ExactInputParams({
          path: pathBytes,
          recipient: address(this),
          amountIn: baseBalance,
          amountOutMinimum: order.amountOutMin
        })
      );
      IERC20(baseToken).safeApprove(liquidityRouter, 0);
    }
    require(amountOut <= order.amountOut, "StopLoss::run: invalid output amount");
    emit StopLossOrderCompleted(amountOut);
  }
}