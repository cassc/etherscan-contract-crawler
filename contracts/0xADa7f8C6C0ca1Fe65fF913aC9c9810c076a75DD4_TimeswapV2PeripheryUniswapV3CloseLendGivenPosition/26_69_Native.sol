// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IWrappedNative} from "../interfaces/external/IWrappedNative.sol";
import {INativeImmutableState} from "../interfaces/INativeImmutableState.sol";
import {INativeWithdraws} from "../interfaces/INativeWithdraws.sol";
import {INativePayments} from "../interfaces/INativePayments.sol";
import {NativeTransfer} from "../libraries/NativeTransfer.sol";

abstract contract NativeImmutableState is INativeImmutableState {
  /// @inheritdoc INativeImmutableState
  address public immutable override wrappedNativeToken;

  constructor(address chosenWrappedNativeToken) {
    wrappedNativeToken = chosenWrappedNativeToken;
  }
}

abstract contract NativeWithdraws is INativeWithdraws, NativeImmutableState {
  error CallerNotWrappedNative(address from);

  error InsufficientWrappedNative(uint256 value);

  receive() external payable {
    if (msg.sender != wrappedNativeToken) revert CallerNotWrappedNative(msg.sender);
  }

  /// @inheritdoc INativeWithdraws
  function unwrapWrappedNatives(uint256 amountMinimum, address recipient) external payable override {
    uint256 balanceWrappedNative = IWrappedNative(wrappedNativeToken).balanceOf(address(this));

    if (balanceWrappedNative < amountMinimum) revert InsufficientWrappedNative(balanceWrappedNative);

    if (balanceWrappedNative != 0) {
      IWrappedNative(wrappedNativeToken).withdraw(balanceWrappedNative);

      NativeTransfer.safeTransferNatives(recipient, balanceWrappedNative);
    }
  }
}

abstract contract NativePayments is INativePayments, NativeImmutableState {
  using SafeERC20 for IERC20;

  /// @inheritdoc INativePayments
  function refundNatives() external payable override {
    if (address(this).balance > 0) NativeTransfer.safeTransferNatives(msg.sender, address(this).balance);
  }

  /// @param token The token to pay
  /// @param payer The entity that must pay
  /// @param recipient The entity that will receive payment
  /// @param value The amount to pay
  function pay(address token, address payer, address recipient, uint256 value) internal {
    if (token == wrappedNativeToken && address(this).balance >= value) {
      // pay with WrappedNative
      IWrappedNative(wrappedNativeToken).deposit{value: value}();

      IERC20(token).safeTransfer(recipient, value);
    } else {
      // pull payment
      IERC20(token).safeTransferFrom(payer, recipient, value);
    }
  }
}