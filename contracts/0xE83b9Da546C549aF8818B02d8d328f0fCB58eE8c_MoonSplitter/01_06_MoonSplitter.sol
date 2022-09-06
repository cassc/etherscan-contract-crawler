//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import {PaymentSplitter} from "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract MoonSplitter is PaymentSplitter {
  constructor(address[] memory payees, uint256[] memory shares_) payable PaymentSplitter(payees, shares_) {}
}