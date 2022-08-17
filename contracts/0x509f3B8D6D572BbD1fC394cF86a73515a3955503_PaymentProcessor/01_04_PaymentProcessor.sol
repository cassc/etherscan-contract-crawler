// SPDX-License-Identifier: MIT
// Developed by: dxsoftware.net

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaymentProcessor is Ownable {
  address payable public paymentReceiver;

  event PaymentDone(address payer, uint256 amount, address token, string paymentId, uint256 date);

  constructor(address payable _paymentReceiver) {
    paymentReceiver = _paymentReceiver;
  }

  function setPaymentReceiver(address payable _paymentReceiver) external onlyOwner {
    paymentReceiver = _paymentReceiver;
  }

  function payToken(
    IERC20 token,
    uint256 amount,
    string calldata paymentId
  ) external {
    token.transferFrom(msg.sender, paymentReceiver, amount);
    emit PaymentDone(msg.sender, amount, address(token), paymentId, block.timestamp);
  }

  function pay(string calldata paymentId) external payable {
    paymentReceiver.transfer(msg.value);
    emit PaymentDone(msg.sender, msg.value, address(0x0), paymentId, block.timestamp);
  }
}