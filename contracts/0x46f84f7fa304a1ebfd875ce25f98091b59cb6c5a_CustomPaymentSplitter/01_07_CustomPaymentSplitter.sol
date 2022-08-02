//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract CustomPaymentSplitter is PaymentSplitter {
    constructor(address[] memory shareholders_, uint256[] memory shares_) PaymentSplitter(shareholders_, shares_) {}
}