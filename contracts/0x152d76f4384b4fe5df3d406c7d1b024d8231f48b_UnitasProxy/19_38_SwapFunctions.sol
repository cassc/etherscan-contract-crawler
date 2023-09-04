// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./interfaces/ISwapFunctions.sol";
import "./utils/Errors.sol";

abstract contract SwapFunctions is ISwapFunctions {
    using MathUpgradeable for uint256;

    /**
     * @notice Calculates the swapping result
     * @param request The struct of required parameters for computing the result
     * @return amountIn The amount of `tokenIn` to be spent
     * @return amountOut The amount of `tokenOut` to be obtained
     * @return fee The amount of fee denominated in `feeToken`
     */
    function _calculateSwapResult(SwapRequest memory request)
        internal
        view
        virtual
        returns (uint256 amountIn, uint256 amountOut, uint256 fee)
    {
        _validateFeeFraction(request.feeNumerator, request.feeBase);

        if (request.amountType == AmountType.In) {
            return _calculateSwapResultByAmountIn(request);
        } else {
            return _calculateSwapResultByAmountOut(request);
        }
    }

    /**
     * @notice Calculates the swapping result when `amountType` is `In`
     * @param request The struct of required parameters for computing the result
     * @return amountIn The amount of `tokenIn` to be spent
     * @return amountOut The amount of `tokenOut` to be obtained
     * @return fee The amount of fee denominated in `feeToken`
     */
    function _calculateSwapResultByAmountIn(SwapRequest memory request)
        internal
        view
        virtual
        returns (uint256 amountIn, uint256 amountOut, uint256 fee)
    {
        amountIn = request.amount;

        if (request.tokenIn == request.feeToken) {
            // When tokenIn is feeToken, subtracts the fee before converting the amount
            fee = _getFeeByAmountWithFee(amountIn, request.feeNumerator, request.feeBase);
            amountOut = _convert(
                request.tokenIn,
                request.tokenOut,
                amountIn - fee,
                MathUpgradeable.Rounding.Down,
                request.price,
                request.priceBase,
                request.quoteToken
            );
        } else {
            // When tokenOut is feeToken, subtracts the fee after converting the amount
            amountOut = _convert(
                request.tokenIn,
                request.tokenOut,
                amountIn,
                MathUpgradeable.Rounding.Down,
                request.price,
                request.priceBase,
                request.quoteToken
            );
            fee = _getFeeByAmountWithFee(amountOut, request.feeNumerator, request.feeBase);
            amountOut -= fee;
        }
    }

    /**
     * @notice Calculates the swapping result when `amountType` is `Out`
     * @param request The struct of required parameters for computing the result
     * @return amountIn The amount of `tokenIn` to be spent
     * @return amountOut The amount of `tokenOut` to be obtained
     * @return fee The amount of fee denominated in `feeToken`
     */
    function _calculateSwapResultByAmountOut(SwapRequest memory request)
        internal
        view
        virtual
        returns (uint256 amountIn, uint256 amountOut, uint256 fee)
    {
        amountOut = request.amount;

        if (request.tokenIn == request.feeToken) {
            // When tokenIn is feeToken, adds the fee after converting the amount
            amountIn = _convert(
                request.tokenOut,
                request.tokenIn,
                amountOut,
                MathUpgradeable.Rounding.Up,
                request.price,
                request.priceBase,
                request.quoteToken
            );
            fee = _getFeeByAmountWithoutFee(amountIn, request.feeNumerator, request.feeBase);
            amountIn += fee;
        } else {
            // When tokenOut is feeToken, adds the fee before converting the amount
            fee = _getFeeByAmountWithoutFee(amountOut, request.feeNumerator, request.feeBase);
            amountIn = _convert(
                request.tokenOut,
                request.tokenIn,
                amountOut + fee,
                MathUpgradeable.Rounding.Up,
                request.price,
                request.priceBase,
                request.quoteToken
            );
        }
    }

    /**
     * @notice Reverts if the fee fraction is invalid. A valid swapping fee must be zero or less than the amount.
     * @param numerator Fee numerator
     * @param denominator Fee denominator
     */
    function _validateFeeFraction(uint256 numerator, uint256 denominator) internal view virtual {
        _require((numerator == 0 && denominator == 0) || numerator < denominator, Errors.FEE_FRACTION_INVALID);
    }

    /**
     * @notice Calculates the fee based on `amount` that includes fee
     */
    function _getFeeByAmountWithFee(uint256 amount, uint256 feeNumerator, uint256 feeDenominator)
        internal
        view
        virtual
        returns (uint256)
    {
        if (feeDenominator == 0) {
            return 0;
        } else {
            return (amount * feeNumerator).ceilDiv(feeDenominator);
        }
    }

    /**
     * @notice Calculates the fee based on `amount` that excludes fee
     */
    function _getFeeByAmountWithoutFee(uint256 amount, uint256 feeNumerator, uint256 feeDenominator)
        internal
        view
        virtual
        returns (uint256)
    {
        if (feeDenominator == 0) {
            return 0;
        } else {
            uint256 amountWithFee = (amount * feeDenominator).ceilDiv(feeDenominator - feeNumerator);
            return amountWithFee - amount;
        }
    }

    /**
     * @notice Converts the amount
     * @param fromToken Address of source token
     * @param toToken Address of target token
     * @param fromAmount Amount of `fromToken`
     * @param rounding Rounding mode to calculate return value
     * @param price The exchange rate
     * @param priceBase Ten to the power of the price decimal (10 ** price decimal)
     * @param quoteToken The quote currency of the price
     * @return Amount of `toToken`
     */
    function _convert(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        MathUpgradeable.Rounding rounding,
        uint256 price,
        uint256 priceBase,
        address quoteToken
    ) internal view virtual returns (uint256) {
        if (fromToken == toToken) {
            return fromAmount;
        } else if (toToken == quoteToken) {
            return _convertByFromPrice(fromToken, toToken, fromAmount, rounding, price, priceBase);
        } else if (fromToken == quoteToken) {
            return _convertByToPrice(fromToken, toToken, fromAmount, rounding, price, priceBase);
        } else {
            _revert(Errors.PARAMETER_INVALID);
        }
    }

    /**
     * @notice Converts the amount when the price is based on `fromToken`
     * @param fromToken Address of source token
     * @param toToken Address of target token
     * @param fromAmount Amount of `fromToken`
     * @param rounding Rounding mode to calculate return value
     * @param price The exchange rate of `fromToken`/`toToken`
     * @param priceBase Ten to the power of the price decimal (10 ** price decimal)
     * @return Amount of `toToken`
     */
    function _convertByFromPrice(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        MathUpgradeable.Rounding rounding,
        uint256 price,
        uint256 priceBase
    ) internal view virtual returns (uint256) {
        uint256 fromBase = 10 ** IERC20Metadata(fromToken).decimals();
        uint256 toBase = 10 ** IERC20Metadata(toToken).decimals();

        return fromAmount.mulDiv(price * toBase, priceBase * fromBase, rounding);
    }

    /**
     * @notice Converts the amount when the price is based on `toToken`, reverts if `price` is zero.
     * @param fromToken Address of source token
     * @param toToken Address of target token
     * @param fromAmount Amount of `fromToken`
     * @param rounding Rounding mode to calculate return value
     * @param price The exchange rate of `toToken`/`fromToken`
     * @param priceBase Ten to the power of the price decimal (10 ** price decimal)
     * @return Amount of `toToken`
     */
    function _convertByToPrice(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        MathUpgradeable.Rounding rounding,
        uint256 price,
        uint256 priceBase
    ) internal view virtual returns (uint256) {
        uint256 fromBase = 10 ** IERC20Metadata(fromToken).decimals();
        uint256 toBase = 10 ** IERC20Metadata(toToken).decimals();

        return fromAmount.mulDiv(priceBase * toBase, price * fromBase, rounding);
    }
}