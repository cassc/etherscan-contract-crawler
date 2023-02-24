// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {WhopWithdrawable} from "./Withdrawable.sol";

contract WhopPaymentGateway is Ownable, WhopWithdrawable {
  using ECDSA for bytes32;

  error AccessDenied();
  error NotOwner();
  error SignatureMismatch();
  error TooManyDividends();
  error InsufficientFunds();
  error PaymentFailed();
  error CheckoutAlreadyCompleted();

  event PaymentCompleted(string indexed receipt_id, uint256 fees_paid);

  address private _signer;
  address private _subscriptionExecutor;
  mapping(string => bool) private _completed;

  struct Payment {
    address from;
    address token;
    uint256 amount;
    string receipt_id;
    uint32 divisor;
    address[] recipients;
    uint32[] dividends;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  constructor(address signer, address subscriptionExecutor) {
    _signer = signer;
    _subscriptionExecutor = subscriptionExecutor;
  }

  function processPayment(Payment calldata payment) external payable {
    address from = payment.from;
    if (from == address(0)) from = msg.sender;
    else if (msg.sender != _subscriptionExecutor) revert AccessDenied();
    if (_completed[payment.receipt_id]) revert CheckoutAlreadyCompleted();
    _confirmPaymentSignature(payment);

    _completed[payment.receipt_id] = true;

    uint256 fees_paid = payment.token == address(0)
      ? _processEthPayment(payment)
      : _processERC20Payment(from, payment);

    emit PaymentCompleted(payment.receipt_id, fees_paid);
  }

  function setSigner(address signer) external onlyOwner {
    _signer = signer;
  }

  function setSubscriptionExecutor(address subscriptionExecutor)
    external
    onlyOwner
  {
    _subscriptionExecutor = subscriptionExecutor;
  }

  function _processEthPayment(Payment calldata payment)
    private
    returns (uint256)
  {
    if (payment.amount > msg.value) revert InsufficientFunds();
    uint256 amount_left = payment.amount;
    for (uint8 i; i < payment.recipients.length; i++) {
      uint256 amount = (payment.amount / payment.divisor) *
        payment.dividends[i];
      if (amount > 0) {
        if (amount > amount_left) revert TooManyDividends();
        amount_left -= amount;
        (bool success, ) = payment.recipients[i].call{value: amount}("");
        if (!success) revert PaymentFailed();
      }
    }

    return amount_left;
  }

  function _processERC20Payment(address from, Payment calldata payment)
    private
    returns (uint256)
  {
    uint256 amount_left = payment.amount;
    IERC20 token = IERC20(payment.token);
    for (uint8 i; i < payment.recipients.length; i++) {
      uint256 amount = (payment.amount / payment.divisor) *
        payment.dividends[i];
      if (amount > 0) {
        if (amount > amount_left) revert TooManyDividends();
        amount_left -= amount;
        bool success = token.transferFrom(from, payment.recipients[i], amount);
        if (!success) revert PaymentFailed();
      }
    }
    bool success2 = token.transferFrom(from, address(this), amount_left);
    if (!success2) revert PaymentFailed();
    return amount_left;
  }

  function _confirmPaymentSignature(Payment calldata payment) private view {
    if (
      keccak256(
        abi.encodePacked(
          payment.from,
          payment.token,
          payment.amount,
          payment.receipt_id,
          payment.divisor,
          payment.recipients,
          payment.dividends
        )
      ).toEthSignedMessageHash().recover(payment.v, payment.r, payment.s) !=
      _signer
    ) revert SignatureMismatch();
  }

  function _beforeWithdraw(
    address withdrawer,
    address,
    address,
    uint256 amount
  ) internal view override returns (uint256) {
    if (withdrawer != owner()) revert NotOwner();
    return amount;
  }
}