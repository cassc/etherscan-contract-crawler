// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../../interfaces/IUniswapV3.sol";
import "../../interfaces/IUniswapV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// @title transforms V2 into V3
contract UniswapV2toV3 is IUniswapV3 {
  // audit(B): M03
  using SafeERC20 for ERC20;

  IUniswapV2 immutable uniswapV2;

  constructor(IUniswapV2 _uniswapV2) {
    uniswapV2 = _uniswapV2;
  }

  /// @inheritdoc IUniswapV3
  function exactInputSingle(
    ExactInputSingleParams calldata params
  ) external payable override returns (uint256 amountOut) {
    ERC20(params.tokenIn).safeTransferFrom(
      msg.sender,
      address(this),
      params.amountIn
    );
    ERC20(params.tokenIn).safeApprove(address(uniswapV2), params.amountIn);

    address[] memory path = new address[](2);
    path[0] = params.tokenIn;
    path[1] = params.tokenOut;
    uint256[] memory amountsOut = uniswapV2.swapExactTokensForTokens(
      params.amountIn,
      params.amountOutMinimum,
      path,
      params.recipient,
      params.deadline
    );
    amountOut = amountsOut[amountsOut.length - 1];
  }

  /// @inheritdoc IUniswapV3
  function exactOutputSingle(
    ExactOutputSingleParams calldata params
  ) external payable override returns (uint256 amountIn) {
    ERC20(params.tokenIn).safeTransferFrom(
      msg.sender,
      address(this),
      params.amountInMaximum
    );
    ERC20(params.tokenIn).safeApprove(
      address(uniswapV2),
      params.amountInMaximum
    );

    address[] memory path = new address[](2);
    path[0] = params.tokenIn;
    path[1] = params.tokenOut;
    uint256[] memory amountsOut = uniswapV2.swapTokensForExactTokens(
      params.amountOut,
      params.amountInMaximum,
      path,
      params.recipient,
      params.deadline
    );
    amountIn = amountsOut[0];

    if (amountIn < params.amountInMaximum) {
      ERC20(params.tokenIn).safeApprove(address(uniswapV2), 0);
      ERC20(params.tokenIn).safeTransfer(
        msg.sender,
        params.amountInMaximum - amountIn
      );
    }
  }
}