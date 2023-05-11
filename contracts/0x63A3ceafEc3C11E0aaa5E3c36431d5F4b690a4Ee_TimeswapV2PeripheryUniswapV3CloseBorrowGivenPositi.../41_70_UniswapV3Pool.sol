// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IUniswapV3PoolActions} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol";
import {IUniswapV3PoolState} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol";
import {IUniswapV3PoolImmutables} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol";
import {LowGasSafeMath} from "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";
import {LiquidityMath} from "@uniswap/v3-core/contracts/libraries/LiquidityMath.sol";
import {SafeCast} from "@uniswap/v3-core/contracts/libraries/SafeCast.sol";

import {FullMath} from "@timeswap-labs/v2-library/contracts/FullMath.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";
import {CatchError} from "@timeswap-labs/v2-library/contracts/CatchError.sol";

import {PriceConversion} from "./PriceConversion.sol";

import {UniswapV3SwapParam, UniswapV3SwapForRebalanceParam, UniswapV3CalculateSwapParam, UniswapV3CalculateSwapForRebalanceParam} from "../structs/SwapParam.sol";

library UniswapV3PoolLibrary {
  using LowGasSafeMath for int256;
  using SafeCast for uint256;
  using PriceConversion for uint256;
  using Math for uint256;
  using CatchError for bytes;

  error ZeroPoolAddress();

  error PassCalculateInfo(int256 amount0, int256 amount1);

  function checkNotZeroAddress(address pool) internal pure {
    if (pool == address(0)) revert ZeroPoolAddress();
  }

  function passCalculateInfo(int256 amount0, int256 amount1) internal pure {
    revert PassCalculateInfo(amount0, amount1);
  }

  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739;
  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

  function swap(
    address pool,
    UniswapV3SwapParam memory param
  ) internal returns (uint256 tokenAmountIn, uint256 tokenAmountOut) {
    (uint160 sqrtPrice, , , , , , ) = IUniswapV3PoolState(pool).slot0();

    uint160 sqrtStrike = param.strikeLimit != 0
      ? param.strikeLimit.convertTsToUni()
      : (param.zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1);

    if (sqrtStrike <= MIN_SQRT_RATIO) sqrtStrike = MIN_SQRT_RATIO + 1;
    if (sqrtStrike >= MAX_SQRT_RATIO) sqrtStrike = MAX_SQRT_RATIO - 1;

    if (param.zeroForOne ? (sqrtPrice > sqrtStrike) : (sqrtPrice < sqrtStrike)) {
      (int256 amount0, int256 amount1) = IUniswapV3PoolActions(pool).swap(
        param.recipient,
        param.zeroForOne,
        param.exactInput ? param.amount.toInt256() : -param.amount.toInt256(),
        sqrtStrike,
        param.data
      );

      (tokenAmountIn, tokenAmountOut) = param.zeroForOne
        ? (uint256(amount0), uint256(-amount1))
        : (uint256(amount1), uint256(-amount0));
    }
  }

  function swapForRebalance(
    address pool,
    UniswapV3SwapForRebalanceParam memory param
  ) internal returns (uint256 tokenAmountIn, uint256 tokenAmountOut) {
    uint160 sqrtStrike = (
      param.zeroForOne
        ? FullMath.mulDiv(
          param.strikeLimit.convertTsToUni(),
          1 << 16,
          (uint256(1) << 16).unsafeSub(param.transactionFee),
          true
        )
        : FullMath.mulDiv(
          param.strikeLimit.convertTsToUni(),
          (uint256(1) << 16).unsafeSub(param.transactionFee),
          1 << 16,
          false
        )
    ).toUint160();

    if (sqrtStrike <= MIN_SQRT_RATIO) sqrtStrike = MIN_SQRT_RATIO + 1;
    if (sqrtStrike >= MAX_SQRT_RATIO) sqrtStrike = MAX_SQRT_RATIO - 1;

    (int256 amount0, int256 amount1) = IUniswapV3PoolActions(pool).swap(
      param.recipient,
      param.zeroForOne,
      param.exactInput ? param.amount.toInt256() : -param.amount.toInt256(),
      sqrtStrike,
      param.data
    );

    (tokenAmountIn, tokenAmountOut) = param.zeroForOne
      ? (uint256(amount0), uint256(-amount1))
      : (uint256(amount1), uint256(-amount0));
  }

  function calculateSwap(
    address pool,
    UniswapV3CalculateSwapParam memory param
  ) internal returns (uint256 amountIn, uint256 amountOut) {
    (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3PoolState(pool).slot0();

    uint160 sqrtRatioTargetX96 = param.strikeLimit != 0
      ? param.strikeLimit.convertTsToUni()
      : (param.zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1);

    if (sqrtRatioTargetX96 <= MIN_SQRT_RATIO) sqrtRatioTargetX96 = MIN_SQRT_RATIO + 1;
    if (sqrtRatioTargetX96 >= MAX_SQRT_RATIO) sqrtRatioTargetX96 = MAX_SQRT_RATIO - 1;

    if (param.zeroForOne ? sqrtRatioTargetX96 < sqrtPriceX96 : sqrtRatioTargetX96 > sqrtPriceX96) {
      int256 amount0;
      int256 amount1;

      try
        IUniswapV3PoolActions(pool).swap(
          address(this),
          param.zeroForOne,
          param.exactInput ? param.amount.toInt256() : -param.amount.toInt256(),
          sqrtRatioTargetX96,
          param.data
        )
      {} catch (bytes memory reason) {
        (amount0, amount1) = handleRevert(reason);
      }

      (amountIn, amountOut) = param.zeroForOne
        ? (uint256(amount0), uint256(-amount1))
        : (uint256(amount1), uint256(-amount0));
    }
  }

  function calculateSwapForRebalance(
    address pool,
    UniswapV3CalculateSwapForRebalanceParam memory param
  ) internal returns (bool zeroForOne, uint256 amountIn, uint256 amountOut) {
    (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3PoolState(pool).slot0();

    uint160 sqrtRatioTargetX96;
    uint256 amount;
    {
      uint160 baseSqrtRatioTargetX96 = param.strikeLimit.convertTsToUni();

      if (param.token0Amount != 0) {
        uint160 adjustedSqrtRatioTargetX96 = FullMath
          .mulDiv(baseSqrtRatioTargetX96, 1 << 16, (uint256(1) << 16).unsafeSub(param.transactionFee), true)
          .toUint160();

        if (adjustedSqrtRatioTargetX96 < sqrtPriceX96) {
          sqrtRatioTargetX96 = adjustedSqrtRatioTargetX96;
          amount = param.token0Amount;
          zeroForOne = true;
        }
      }

      if (param.token1Amount != 0) {
        uint160 adjustedSqrtRatioTargetX96 = FullMath
          .mulDiv(baseSqrtRatioTargetX96, (uint256(1) << 16).unsafeSub(param.transactionFee), 1 << 16, false)
          .toUint160();

        if (adjustedSqrtRatioTargetX96 > sqrtPriceX96) {
          sqrtRatioTargetX96 = adjustedSqrtRatioTargetX96;
          amount = param.token1Amount;
        }
      }
    }

    if (amount != 0) {
      int256 amount0;
      int256 amount1;

      if (sqrtRatioTargetX96 <= MIN_SQRT_RATIO) sqrtRatioTargetX96 = MIN_SQRT_RATIO + 1;
      if (sqrtRatioTargetX96 >= MAX_SQRT_RATIO) sqrtRatioTargetX96 = MAX_SQRT_RATIO - 1;

      try
        IUniswapV3PoolActions(pool).swap(address(this), zeroForOne, amount.toInt256(), sqrtRatioTargetX96, param.data)
      {} catch (bytes memory reason) {
        (amount0, amount1) = handleRevert(reason);
      }

      (amountIn, amountOut) = zeroForOne
        ? (uint256(amount0), uint256(-amount1))
        : (uint256(amount1), uint256(-amount0));
    }
  }

  function handleRevert(bytes memory reason) private pure returns (int256 amount0, int256 amount1) {
    return abi.decode(reason.catchError(PassCalculateInfo.selector), (int256, int256));
  }
}