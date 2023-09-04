// SPDX-License-Identifier: GPL-2.0-or-later
pragma abicoder v2;
pragma solidity >=0.7.5;

import '@violetprotocol/mauve-periphery/contracts/base/EATMulticallPeripheryPaymentsWithFee.sol';

import '../interfaces/IPeripheryPaymentsWithFeeExtended.sol';
import './EATMulticallPeripheryPaymentsExtended.sol';

abstract contract EATMulticallPeripheryPaymentsWithFeeExtended is
    IPeripheryPaymentsWithFeeExtended,
    EATMulticallPeripheryPaymentsExtended,
    EATMulticallPeripheryPaymentsWithFee
{
    /// @inheritdoc IPeripheryPaymentsWithFeeExtended
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external payable override {
        super.unwrapWETH9WithFee(amountMinimum, msg.sender, feeBips, feeRecipient);
    }

    /// @inheritdoc IPeripheryPaymentsWithFeeExtended
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external payable override {
        super.sweepTokenWithFee(token, amountMinimum, msg.sender, feeBips, feeRecipient);
    }
}