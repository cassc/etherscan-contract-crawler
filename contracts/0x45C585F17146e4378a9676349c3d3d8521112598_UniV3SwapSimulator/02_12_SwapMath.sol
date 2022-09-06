// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "FullMath.sol";
import "SqrtPriceMath.sol";

struct SwapExactInParam{
    uint256 _amountIn;
    uint24 _fee;
    uint160 _currentPriceX96;
    uint160 _targetPriceX96;
    uint128 _liquidity;
    bool _zeroForOne;
}

// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/SwapMath.sol
library SwapMath {
    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input or output amount is remaining to be swapped in/out
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    /// @return feeAmount The amount of input that will be taken as a fee
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
        bool exactIn = amountRemaining >= 0;

        {
          if (exactIn) {
            SwapExactInParam memory _exactInParams = SwapExactInParam(uint256(amountRemaining), feePips, sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, zeroForOne);
            (uint256 _amtIn, uint160 _nextPrice) = _getExactInNextPrice(_exactInParams);
            amountIn = _amtIn;
            sqrtRatioNextX96 = _nextPrice;
          } else {
            amountOut = zeroForOne
                ? SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false)
                : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false);
            if (uint256(-amountRemaining) >= amountOut) sqrtRatioNextX96 = sqrtRatioTargetX96;
            else
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    uint256(-amountRemaining),
                    zeroForOne
                );
          }
        }

        bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

        // get the input/output amounts
        {
          if (zeroForOne) {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount0Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true);
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount1Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false);
          }else {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true);
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false);
          }
        }

        // cap the output amount to not exceed the remaining output amount
        if (!exactIn && amountOut > uint256(-amountRemaining)) {
            amountOut = uint256(-amountRemaining);
        }

        if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
            // we didn't reach the target, so take the remainder of the maximum input as fee
            feeAmount = uint256(amountRemaining) - amountIn;
        } else {
            feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
        }
    }
	
    function _getExactInNextPrice(SwapExactInParam memory _exactInParams) internal pure returns (uint256, uint160){
        uint160 sqrtRatioNextX96;
        uint256 amountRemainingLessFee = FullMath.mulDiv(_exactInParams._amountIn, 1e6 - (_exactInParams._fee), 1e6);
        uint256 amountIn = _exactInParams._zeroForOne? SqrtPriceMath.getAmount0Delta(_exactInParams._targetPriceX96, _exactInParams._currentPriceX96, _exactInParams._liquidity, true) : 
                                                       SqrtPriceMath.getAmount1Delta(_exactInParams._currentPriceX96, _exactInParams._targetPriceX96, _exactInParams._liquidity, true);
        if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = _exactInParams._targetPriceX96;
        else sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(_exactInParams._currentPriceX96, _exactInParams._liquidity, amountRemainingLessFee, _exactInParams._zeroForOne);
        return (amountIn, sqrtRatioNextX96);
    }
}