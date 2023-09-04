// SPDX-License-Identifier: GPL-2.0-or-later
pragma abicoder v2;
pragma solidity >=0.7.5;

import '@violetprotocol/mauve-periphery/contracts/base/EATMulticallPeripheryPayments.sol';
import '@violetprotocol/mauve-periphery/contracts/libraries/TransferHelper.sol';

import './EATMulticallExtended.sol';
import '../interfaces/IPeripheryPaymentsExtended.sol';

abstract contract EATMulticallPeripheryPaymentsExtended is
    IPeripheryPaymentsExtended,
    EATMulticallExtended,
    EATMulticallPeripheryPayments
{
    /// @inheritdoc IPeripheryPaymentsExtended
    function unwrapWETH9(uint256 amountMinimum) external payable override onlySelfMulticall {
        super.unwrapWETH9(amountMinimum, msg.sender);
    }

    /// @inheritdoc IPeripheryPaymentsExtended
    function wrapETH(uint256 value) external payable override {
        IWETH9(WETH9).deposit{value: value}();
    }

    /// @inheritdoc IPeripheryPaymentsExtended
    function sweepToken(address token, uint256 amountMinimum) external payable override onlySelfMulticall {
        super.sweepToken(token, amountMinimum, msg.sender);
    }

    /// @inheritdoc IPeripheryPaymentsExtended
    function pull(address token, uint256 value) external payable override onlySelfMulticall {
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), value);
    }
}