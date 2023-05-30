// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@gridexprotocol/core/contracts/interfaces/IWETHMinimum.sol";
import "./interfaces/IPayments.sol";

abstract contract AbstractPayments is IPayments, Context {
    /// @dev The address of IGridFactory
    address public immutable gridFactory;
    /// @dev The address of IWETHMinimum
    address public immutable weth9;

    constructor(address _gridFactory, address _weth9) {
        // AP_NC: not contract
        require(Address.isContract(_gridFactory), "AP_NC");
        require(Address.isContract(_weth9), "AP_NC");

        gridFactory = _gridFactory;
        weth9 = _weth9;
    }

    modifier checkDeadline(uint256 deadline) {
        // AP_TTO: transaction too old
        require(block.timestamp <= deadline, "AP_TTO");
        _;
    }

    receive() external payable {
        // AP_WETH9: not WETH9
        require(_msgSender() == weth9, "AP_WETH9");
    }

    /// @inheritdoc IPayments
    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable override {
        uint256 balanceWETH9 = IWETHMinimum(weth9).balanceOf(address(this));
        // AP_IWETH9: insufficient WETH9
        require(balanceWETH9 >= amountMinimum, "AP_IWETH9");

        if (balanceWETH9 > 0) {
            IWETHMinimum(weth9).withdraw(balanceWETH9);
            Address.sendValue(payable(recipient), balanceWETH9);
        }
    }

    /// @inheritdoc IPayments
    function sweepToken(address token, uint256 amountMinimum, address recipient) public payable override {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        // AP_ITKN: insufficient token
        require(balanceToken >= amountMinimum, "AP_ITKN");

        if (balanceToken > 0) SafeERC20.safeTransfer(IERC20(token), recipient, balanceToken);
    }

    /// @inheritdoc IPayments
    function refundNativeToken() external payable {
        if (address(this).balance > 0) Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    /// @dev Pays the token to the recipient
    /// @param token The token to pay
    /// @param payer The address of the payment token
    /// @param recipient The address that will receive the payment
    /// @param amount The amount to pay
    function pay(address token, address payer, address recipient, uint256 amount) internal {
        if (token == weth9 && address(this).balance >= amount) {
            // pay with WETH9
            Address.sendValue(payable(weth9), amount);
            IWETHMinimum(weth9).transfer(recipient, amount);
        } else if (payer == address(this)) SafeERC20.safeTransfer(IERC20(token), recipient, amount);
        else SafeERC20.safeTransferFrom(IERC20(token), payer, recipient, amount);
    }
}