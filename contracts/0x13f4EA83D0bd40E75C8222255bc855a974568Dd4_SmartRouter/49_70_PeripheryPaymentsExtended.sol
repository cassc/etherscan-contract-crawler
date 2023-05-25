// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@pancakeswap/v3-periphery/contracts/base/PeripheryPayments.sol';
import '@pancakeswap/v3-periphery/contracts/libraries/TransferHelper.sol';

import '../interfaces/IPeripheryPaymentsExtended.sol';

abstract contract PeripheryPaymentsExtended is IPeripheryPaymentsExtended, PeripheryPayments {
    /**
    /// @inheritdoc IPeripheryPaymentsExtended
    function unwrapWETH(uint256 amount, address to) external payable override {
        uint256 balance = IWETH9(WETH9).balanceOf(msg.sender);
        require(balance >= amount);
        TransferHelper.safeTransferFrom(WETH9, msg.sender, address(this), amount);
        IWETH9(WETH9).withdraw(amount);
        TransferHelper.safeTransferETH(to, amount);
    }
    */

    /// @inheritdoc IPeripheryPaymentsExtended
    function wrapETH(uint256 value) external payable override {
        IWETH9(WETH9).deposit{value: value}();
    }

    /// @inheritdoc IPeripheryPaymentsExtended
    function sweepToken(address token, uint256 amountMinimum) external payable override {
        sweepToken(token, amountMinimum, msg.sender);
    }

    /// @inheritdoc IPeripheryPaymentsExtended
    function pull(address token, uint256 value) external payable override {
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), value);
    }
}