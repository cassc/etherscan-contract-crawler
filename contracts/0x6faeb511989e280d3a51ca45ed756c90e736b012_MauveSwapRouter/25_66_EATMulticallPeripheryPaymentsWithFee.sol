// SPDX-License-Identifier: GPL-2.0-or-later
pragma abicoder v2;
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@violetprotocol/mauve-core/contracts/libraries/LowGasSafeMath.sol';

import '../interfaces/external/IWETH9.sol';
import '../libraries/TransferHelper.sol';
import '../interfaces/IPeripheryPaymentsWithFee.sol';

import './PeripheryPaymentsWithFee.sol';
import './EATMulticallPeripheryPayments.sol';

abstract contract EATMulticallPeripheryPaymentsWithFee is PeripheryPaymentsWithFee, EATMulticall {
    using LowGasSafeMath for uint256;

    /// @inheritdoc IPeripheryPayments
    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable override onlySelfMulticall {
        super.unwrapWETH9(amountMinimum, recipient);
    }

    /// @inheritdoc IPeripheryPayments
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) public payable override onlySelfMulticall {
        super.sweepToken(token, amountMinimum, recipient);
    }

    /// @inheritdoc IPeripheryPayments
    function refundETH() public payable override onlySelfMulticall {
        super.refundETH();
    }

    /// @inheritdoc IPeripheryPaymentsWithFee
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override onlySelfMulticall {
        super.unwrapWETH9WithFee(amountMinimum, recipient, feeBips, feeRecipient);
    }

    /// @inheritdoc IPeripheryPaymentsWithFee
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override onlySelfMulticall {
        super.sweepTokenWithFee(token, amountMinimum, recipient, feeBips, feeRecipient);
    }
}