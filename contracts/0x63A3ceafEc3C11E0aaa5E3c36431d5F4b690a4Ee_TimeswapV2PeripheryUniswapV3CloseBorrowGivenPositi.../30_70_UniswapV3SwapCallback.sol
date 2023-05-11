// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IUniswapV3SwapCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

import {IUniswapImmutableState} from "../interfaces/IUniswapImmutableState.sol";

import {Verify} from "../libraries/Verify.sol";
import {UniswapV3PoolLibrary} from "../libraries/UniswapV3Pool.sol";

import {NativePayments} from "./Native.sol";

abstract contract UniswapImmutableState is IUniswapImmutableState {
  /// @inheritdoc IUniswapImmutableState
  address public immutable override uniswapV3Factory;

  constructor(address chosenUniswapV3Factory) {
    uniswapV3Factory = chosenUniswapV3Factory;
  }
}

abstract contract UniswapCalculate is UniswapImmutableState {
  function uniswapCalculate(int256 amount0Delta, int256 amount1Delta, bytes memory data) internal view {
    (address token0, address token1, uint24 uniswapV3Fee) = abi.decode(data, (address, address, uint24));

    Verify.uniswapV3Pool(uniswapV3Factory, token0, token1, uniswapV3Fee);

    UniswapV3PoolLibrary.passCalculateInfo(amount0Delta, amount1Delta);
  }
}

abstract contract UniswapV3Callback is UniswapCalculate, IUniswapV3SwapCallback {
  using SafeERC20 for IERC20;

  function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
    (bool hasStateChange, bytes memory innerData) = abi.decode(data, (bool, bytes));

    if (hasStateChange) {
      (address token0, address token1, uint24 uniswapV3Fee) = abi.decode(innerData, (address, address, uint24));

      Verify.uniswapV3Pool(uniswapV3Factory, token0, token1, uniswapV3Fee);

      IERC20(amount0Delta > 0 ? token0 : token1).safeTransfer(
        msg.sender,
        uint256(amount0Delta > 0 ? amount0Delta : amount1Delta)
      );
    } else uniswapCalculate(amount0Delta, amount1Delta, innerData);
  }
}

abstract contract UniswapV3CallbackWithNative is UniswapCalculate, IUniswapV3SwapCallback, NativePayments {
  using SafeERC20 for IERC20;

  function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
    (bool hasStateChange, bytes memory innerData) = abi.decode(data, (bool, bytes));

    if (hasStateChange) {
      (address msgSender, address token0, address token1, uint24 uniswapV3Fee) = abi.decode(
        innerData,
        (address, address, address, uint24)
      );

      Verify.uniswapV3Pool(uniswapV3Factory, token0, token1, uniswapV3Fee);

      pay(
        amount0Delta > 0 ? token0 : token1,
        msgSender,
        msg.sender,
        uint256(amount0Delta > 0 ? amount0Delta : amount1Delta)
      );
    } else uniswapCalculate(amount0Delta, amount1Delta, innerData);
  }
}

abstract contract UniswapV3CallbackWithOptionalNative is UniswapCalculate, IUniswapV3SwapCallback, NativePayments {
  using SafeERC20 for IERC20;

  function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
    (bool hasStateChange, bytes memory innerData) = abi.decode(data, (bool, bytes));

    if (hasStateChange) {
      (address msgSender, address token0, address token1, uint24 uniswapV3Fee) = abi.decode(
        innerData,
        (address, address, address, uint24)
      );

      Verify.uniswapV3Pool(uniswapV3Factory, token0, token1, uniswapV3Fee);

      if (msgSender == address(this))
        IERC20(amount0Delta > 0 ? token0 : token1).safeTransfer(
          msg.sender,
          uint256(amount0Delta > 0 ? amount0Delta : amount1Delta)
        );
      else
        pay(
          amount0Delta > 0 ? token0 : token1,
          msgSender,
          msg.sender,
          uint256(amount0Delta > 0 ? amount0Delta : amount1Delta)
        );
    } else uniswapCalculate(amount0Delta, amount1Delta, innerData);
  }
}