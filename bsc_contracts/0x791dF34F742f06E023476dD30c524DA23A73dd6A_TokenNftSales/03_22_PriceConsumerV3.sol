// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

abstract contract PriceConsumerV3 {
  AggregatorV3Interface internal priceFeed;

  int256 private fakePrice = 2000 * 10**8; // remember to divide by 10 ** 8

  constructor() {
    if (block.chainid == 56) {
      // BSC mainnet
      priceFeed = AggregatorV3Interface(
        0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
      );
    } else if (block.chainid == 97) {
      // BSC testnet
      priceFeed = AggregatorV3Interface(
        0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
      );
    } else {
      // Unit-test and thus take it from BSC testnet
      priceFeed = AggregatorV3Interface(
        0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
      );
    }
  }

  // The returned price must be divided by 10**8
  function getThePrice() public view returns (int256) {
    if (block.chainid == 56 || block.chainid == 97) {
      (, int256 price, , , ) = priceFeed.latestRoundData();
      return price;
    } else {
      // for unit-test
      return fakePrice;
    }
  }
}