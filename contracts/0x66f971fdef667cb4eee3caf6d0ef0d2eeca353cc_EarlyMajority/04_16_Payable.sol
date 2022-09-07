// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.16;

import "./Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract Payable is Ownable {

  address private _paymentRecipient;

  constructor() {
   _paymentRecipient = owner();
  }

  function setPaymentRecipient(address recipient) external onlyOwner {
    _paymentRecipient = recipient;
  }

  function release() external virtual onlyOwner {
    uint256 balance = address(this).balance;
    Address.sendValue(payable(_paymentRecipient), balance);
  }
}