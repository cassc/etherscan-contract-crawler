// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../interfaces/IPeripheryPayments.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./TransferHelper.sol";
import "./IWETH9.sol";
import "./PeripheryState.sol";
import "./Weth9Unwrapper.sol";

abstract contract PeripheryPayments is IPeripheryPayments, PeripheryState {
    receive() external payable {
        require(msg.sender == WETH9, "Not WETH9");
    }

    // public methods
    /// @inheritdoc IPeripheryPayments
    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable override {
        uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
        require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

        if (balanceWETH9 > 0) {
            TransferHelper.safeTransfer(WETH9, weth9Unwrapper, balanceWETH9);
            Weth9Unwrapper(weth9Unwrapper).unwrapWeth9(balanceWETH9, recipient);
        }
    }

    /// @inheritdoc IPeripheryPayments
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) public payable override {
        uint256 balanceToken = IERC20Upgradeable(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            TransferHelper.safeTransfer(token, recipient, balanceToken);
        }
    }

    /// @inheritdoc IPeripheryPayments
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override {
        require(feeBips > 0 && feeBips <= 100, "Fee out of range");

        uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
        require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

        if (balanceWETH9 > 0) {
            IWETH9(WETH9).withdraw(balanceWETH9);
            uint256 feeAmount = (balanceWETH9 * feeBips) / 100_00;
            if (feeAmount > 0) TransferHelper.safeTransferETH(feeRecipient, feeAmount);
            TransferHelper.safeTransferETH(recipient, balanceWETH9 - feeAmount);
        }
    }

    /// @inheritdoc IPeripheryPayments
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) public payable override {
        require(feeBips > 0 && feeBips <= 100, "Fee out of range");

        uint256 balanceToken = IERC20Upgradeable(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            uint256 feeAmount = (balanceToken * feeBips) / 100_00;
            if (feeAmount > 0) TransferHelper.safeTransfer(token, feeRecipient, feeAmount);
            TransferHelper.safeTransfer(token, recipient, balanceToken - feeAmount);
        }
    }

    // external methods
    /// @inheritdoc IPeripheryPayments
    function refundETH() external payable override {
        if (address(this).balance > 0)
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    function refundETHRecipient(address recipient) public payable {
        if (address(this).balance > 0)
            TransferHelper.safeTransferETH(recipient, address(this).balance);
    }

    function unwrapWETH9(uint256 amountMinimum) external payable {
        unwrapWETH9(amountMinimum, msg.sender);
    }

    function wrapETH(uint256 value) external payable {
        IWETH9(WETH9).deposit{value: value}();
    }

    function sweepToken(address token, uint256 amountMinimum) external payable {
        sweepToken(token, amountMinimum, msg.sender);
    }

    function pull(address token, uint256 value) external payable {
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), value);
    }

    // internal methods
    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(address token, address payer, address recipient, uint256 value) internal {
        if (token == WETH9 && address(this).balance >= value) {
            //require(address(this).balance >= value, "Insufficient native token value");
            // pay with WETH9
            IWETH9(WETH9).deposit{value: value}(); // wrap only what is needed to pay
            IWETH9(WETH9).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }
}