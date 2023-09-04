// SPDX-License-Identifier: GPL-2.0-or-later
pragma abicoder v2;
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../interfaces/IPeripheryPayments.sol';
import '../interfaces/external/IWETH9.sol';

import '../libraries/TransferHelper.sol';

import './PeripheryPayments.sol';
import './EATMulticall.sol';

abstract contract EATMulticallPeripheryPayments is PeripheryPayments, EATMulticall {
    /// @inheritdoc IPeripheryPayments
    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable override {
        super.unwrapWETH9(amountMinimum, recipient);
    }

    /// @inheritdoc IPeripheryPayments
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) public payable override {
        super.sweepToken(token, amountMinimum, recipient);
    }

    /// @inheritdoc IPeripheryPayments
    function refundETH() public payable override {
        super.refundETH();
    }
}