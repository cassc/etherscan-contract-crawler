// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.9;

import "../utils/FullMath.sol";
import "../utils/SqrtPriceMath.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";
import "../core_libraries/FixedAndVariableMath.sol";

/// @title Computes the result of a swap within ticks
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    struct SwapStepParams {
        uint160 sqrtRatioCurrentX96;
        uint160 sqrtRatioTargetX96;
        uint128 liquidity;
        int256 amountRemaining;
        uint256 feePercentageWad;
        uint256 timeToMaturityInSecondsWad;
    }

    function computeFeeAmount(
        uint256 notionalWad,
        uint256 timeToMaturityInSecondsWad,
        uint256 feePercentageWad
    ) internal pure returns (uint256 feeAmount) {
        uint256 timeInYearsWad = FixedAndVariableMath.accrualFact(
            timeToMaturityInSecondsWad
        );

        uint256 feeAmountWad = PRBMathUD60x18.mul(
            notionalWad,
            PRBMathUD60x18.mul(feePercentageWad, timeInYearsWad)
        );

        feeAmount = PRBMathUD60x18.toUint(feeAmountWad);
    }

    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param params.sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param params.sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param params.liquidity The usable params.liquidity
    /// @param params.amountRemaining How much input or output amount is remaining to be swapped in/out
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swa
    /// @return feeAmount Amount of fees in underlying tokens incurred by the position during the swap step, i.e. single iteration of the while loop in the VAMM
    function computeSwapStep(SwapStepParams memory params)
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        bool zeroForOne = params.sqrtRatioCurrentX96 >=
            params.sqrtRatioTargetX96;
        bool exactIn = params.amountRemaining >= 0;

        uint256 amountRemainingAbsolute;

        /// @dev using unchecked block below since overflow is possible when calculating "-amountRemaining" and such overflow would cause a revert
        unchecked {
            amountRemainingAbsolute = uint256(-params.amountRemaining);
        }

        if (exactIn) {
            amountIn = zeroForOne
                ? SqrtPriceMath.getAmount0Delta(
                    params.sqrtRatioTargetX96,
                    params.sqrtRatioCurrentX96,
                    params.liquidity,
                    true
                )
                : SqrtPriceMath.getAmount1Delta(
                    params.sqrtRatioCurrentX96,
                    params.sqrtRatioTargetX96,
                    params.liquidity,
                    true
                );
            if (uint256(params.amountRemaining) >= amountIn)
                sqrtRatioNextX96 = params.sqrtRatioTargetX96;
            else
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                    params.sqrtRatioCurrentX96,
                    params.liquidity,
                    uint256(params.amountRemaining),
                    zeroForOne
                );
        } else {
            amountOut = zeroForOne
                ? SqrtPriceMath.getAmount1Delta(
                    params.sqrtRatioTargetX96,
                    params.sqrtRatioCurrentX96,
                    params.liquidity,
                    false
                )
                : SqrtPriceMath.getAmount0Delta(
                    params.sqrtRatioCurrentX96,
                    params.sqrtRatioTargetX96,
                    params.liquidity,
                    false
                );
            if (amountRemainingAbsolute >= amountOut)
                sqrtRatioNextX96 = params.sqrtRatioTargetX96;
            else
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                    params.sqrtRatioCurrentX96,
                    params.liquidity,
                    amountRemainingAbsolute,
                    zeroForOne
                );
        }

        bool max = params.sqrtRatioTargetX96 == sqrtRatioNextX96;
        uint256 notional;

        // get the input/output amounts
        if (zeroForOne) {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount0Delta(
                    sqrtRatioNextX96,
                    params.sqrtRatioCurrentX96,
                    params.liquidity,
                    true
                );
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount1Delta(
                    sqrtRatioNextX96,
                    params.sqrtRatioCurrentX96,
                    params.liquidity,
                    false
                );
            // variable taker
            notional = amountOut;
        } else {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount1Delta(
                    params.sqrtRatioCurrentX96,
                    sqrtRatioNextX96,
                    params.liquidity,
                    true
                );
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount0Delta(
                    params.sqrtRatioCurrentX96,
                    sqrtRatioNextX96,
                    params.liquidity,
                    false
                );

            // fixed taker
            notional = amountIn;
        }

        // cap the output amount to not exceed the remaining output amount
        if (!exactIn && amountOut > amountRemainingAbsolute) {
            /// @dev if !exact in => fixedTaker => has no effect on notional since notional = amountIn
            amountOut = amountRemainingAbsolute;
        }

        // uint256 notionalWad = PRBMathUD60x18.fromUint(notional);

        feeAmount = computeFeeAmount(
            PRBMathUD60x18.fromUint(notional),
            params.timeToMaturityInSecondsWad,
            params.feePercentageWad
        );
    }
}