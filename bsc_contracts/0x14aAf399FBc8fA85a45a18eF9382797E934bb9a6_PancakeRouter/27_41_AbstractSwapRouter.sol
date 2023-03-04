// SPDX-License-Identifier: GPL-2.0-or-later

import "./AbstractRegistry.sol";
import "./ISwapRouter.sol";
import "./IUniswapV3.sol";
import "../libs/ERC20Fixed.sol";
import "../libs/Errors.sol";
import "../libs/math/FixedPoint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.8.17;
pragma abicoder v2;

abstract contract AbstractSwapRouter is ISwapRouter, Ownable {
  using ERC20Fixed for ERC20;
  using FixedPoint for uint256;

  IUniswapV3 immutable uniswapV3;
  AbstractRegistry immutable registry;

  event SwapEvent(
    address user,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOut
  );

  constructor(
    address _owner,
    IUniswapV3 _uniswapV3,
    AbstractRegistry _registry
  ) {
    _transferOwnership(_owner);
    registry = _registry;
    uniswapV3 = _uniswapV3;
  }

  // modifiers
  modifier onlyApproved() {
    _require(
      registry.hasRole(registry.APPROVED_ROLE(), msg.sender),
      Errors.APPROVED_ONLY
    );
    _;
  }

  function swapGivenIn(
    SwapGivenInInput memory input
  ) external returns (uint256) {
    ERC20(input.tokenIn).transferFromFixed(
      msg.sender,
      address(this),
      input.amountIn
    );
    ERC20(input.tokenIn).approveFixed(address(uniswapV3), input.amountIn);

    IUniswapV3.ExactInputSingleParams memory params = IUniswapV3
      .ExactInputSingleParams({
        tokenIn: input.tokenIn,
        tokenOut: input.tokenOut,
        fee: input.poolFee,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountIn: input.amountIn /
          (10 ** (18 - ERC20(input.tokenIn).decimals())),
        amountOutMinimum: input.amountOutMinimum /
          (10 ** (18 - ERC20(input.tokenOut).decimals())),
        sqrtPriceLimitX96: 0
      });

    uint256 amountOut = uniswapV3.exactInputSingle(params) *
      (10 ** (18 - ERC20(input.tokenOut).decimals()));

    emit SwapEvent(
      msg.sender,
      input.tokenIn,
      input.tokenOut,
      input.amountIn,
      amountOut
    );

    return amountOut;
  }

  function swapGivenOut(
    SwapGivenOutInput memory input
  ) external returns (uint256) {
    ERC20(input.tokenIn).transferFromFixed(
      msg.sender,
      address(this),
      input.amountInMaximum
    );

    // audit(S): UNW-5
    uint256 _amountInMaximum = input.amountInMaximum.min(
      ERC20(input.tokenIn).balanceOfFixed(address(this))
    );

    ERC20(input.tokenIn).approveFixed(address(uniswapV3), _amountInMaximum);

    IUniswapV3.ExactOutputSingleParams memory params = IUniswapV3
      .ExactOutputSingleParams({
        tokenIn: input.tokenIn,
        tokenOut: input.tokenOut,
        fee: input.poolFee,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountOut: input.amountOut /
          (10 ** (18 - ERC20(input.tokenOut).decimals())),
        amountInMaximum: input.amountInMaximum /
          (10 ** (18 - ERC20(input.tokenIn).decimals())),
        sqrtPriceLimitX96: 0
      });

    uint256 amountIn = uniswapV3.exactOutputSingle(params) *
      (10 ** (18 - ERC20(input.tokenIn).decimals()));

    if (amountIn < input.amountInMaximum) {
      ERC20(input.tokenIn).approveFixed(address(uniswapV3), 0);
      ERC20(input.tokenIn).transferFixed(
        msg.sender,
        input.amountInMaximum.sub(amountIn)
      );
    }

    emit SwapEvent(
      msg.sender,
      input.tokenIn,
      input.tokenOut,
      amountIn,
      input.amountOut
    );

    return amountIn;
  }

  function getAmountGivenOut(
    SwapGivenOutInput memory input
  ) external view virtual returns (uint256);

  function getAmountGivenIn(
    SwapGivenInInput memory input
  ) external view virtual returns (uint256);
}