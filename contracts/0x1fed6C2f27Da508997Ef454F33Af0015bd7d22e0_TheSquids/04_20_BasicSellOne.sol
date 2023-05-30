// SPDX-License-Identifier: MIT
// Creator: https://cojodi.com

pragma solidity ^0.8.0;

import "./AbstractBasicSell.sol";

contract BasicSellOne is AbstractBasicSell {
  constructor(uint256 price_) AbstractBasicSell(price_) {}

  modifier isPaymentOk() {
    require(msg.value == price, "wrong amount paid");
    _;
  }
}