// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract CsPaymentSplitter is PaymentSplitter {
  address[] private _payees = [
    0x1937CF8320098a6DCc363c444F8AB97Af4e38FaA, // Gets 30% of the total revenue
    0x65A9a37052250fdbfaAd7f6ec35FB8A7B5e516F9  // Gets 70% of the total revenue
  ];

  uint256[] private _shares = [30, 70];

  constructor () PaymentSplitter(_payees, _shares) payable {
  }
}