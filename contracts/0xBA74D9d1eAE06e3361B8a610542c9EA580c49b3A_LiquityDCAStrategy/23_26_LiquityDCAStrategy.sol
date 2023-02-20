// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import {PercentMath} from "../../lib/PercentMath.sol";
import {LiquityStrategy} from "./LiquityStrategy.sol";

/***
 * An extended version of LiquityStrategy that allows generated yield to be distributed as ETH.
 */
contract LiquityDCAStrategy is LiquityStrategy {
    using PercentMath for uint256;

    error StrategyETHTransferFailed(address to);
    error StrategySwapDataEmpty();
    error StrategyLQTYtoETHSwapFailed();

    event StrategyYieldTransferred(address to, uint256 amount);

    /// @inheritdoc LiquityStrategy
    function transferYield(address _to, uint256 _amount)
        external
        override(LiquityStrategy)
        onlyManager
        returns (uint256)
    {
        uint256 ethBalance = address(this).balance;

        if (ethBalance == 0) return 0;

        uint256 amountInETH = _getExchangeAmountInETH(_amount);

        uint256 ethToTransfer = amountInETH > ethBalance
            ? ethBalance
            : amountInETH;

        _sendETH(_to, ethToTransfer);

        uint256 equivalentAmountInUnderlying = (_amount * ethToTransfer) /
            amountInETH;

        emit StrategyYieldTransferred(_to, equivalentAmountInUnderlying);

        return equivalentAmountInUnderlying;
    }

    /**
     * Swaps LQTY tokens held by the strategy to ETH.
     *
     * @notice Swap data is real-time data obtained from '0x' api.
     *
     * @param _swapTarget the address of the '0x' contract performing the swap.
     * @param _amount the amount of LQTY tokens to swap. Has to match with the amount used to obtain @param _lqtySwapData from '0x' api.
     * @param _lqtySwapData data from '0x' api used to perform LQTY -> ETH swap.
     * @param _ethAmountOutMin minimum amount of ETH to receive for the swap.
     */
    function swapLQTYtoETH(
        address _swapTarget,
        uint256 _amount,
        bytes calldata _lqtySwapData,
        uint256 _ethAmountOutMin
    ) external onlyKeeper {
        _checkSwapTarget(_swapTarget);
        if (_amount == 0) revert StrategyAmountZero();
        if (_lqtySwapData.length == 0) revert StrategySwapDataEmpty();

        uint256 lqtyBalance = lqty.balanceOf(address(this));
        if (_amount > lqtyBalance) revert StrategyNotEnoughLQTY();

        lqty.approve(_swapTarget, _amount);

        uint256 ethBalance = address(this).balance;

        (bool success, ) = _swapTarget.call{value: 0}(_lqtySwapData);
        if (!success) revert StrategyLQTYtoETHSwapFailed();

        if (address(this).balance < ethBalance + _ethAmountOutMin)
            revert StrategyInsufficientOutputAmount();
    }

    /**
     * Gets the amount of ETH that can be exchanged for the given amount of underlying asset (LUSD).
     * Uses curve LUSD/USDT & ETH/USDT pools to calculate the amount of ETH that can be exchanged for the given amount of LUSD.
     *
     * @param _underlyingAmount The amount of underlying asset (LUSD) to be exchanged.
     */
    function _getExchangeAmountInETH(uint256 _underlyingAmount)
        internal
        view
        returns (uint256)
    {
        uint256 amountInUSDT = curveExchange.get_exchange_amount(
            LUSD_CURVE_POOL,
            address(underlying),
            USDT,
            _underlyingAmount
        );

        uint256 amountInETH = curveExchange.get_exchange_amount(
            WETH_CURVE_POOL,
            USDT,
            WETH,
            amountInUSDT
        );

        return amountInETH;
    }

    /**
     * Sends ETH to the specified @param _to address. Reverts if the transfer fails.
     *
     * @param _to The address to send ETH to
     * @param _amount The amount of ETH to send
     */
    function _sendETH(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");

        if (!sent) revert StrategyETHTransferFailed(_to);
    }
}