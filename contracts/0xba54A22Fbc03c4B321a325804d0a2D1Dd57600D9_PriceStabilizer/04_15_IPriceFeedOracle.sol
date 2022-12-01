// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../external/AggregatorV3Interface.sol";

interface IPriceFeedOracle {
  struct Feed {
    AggregatorV3Interface aggregator;
    uint8 decimals;
    bool invert;
  }

  function getPrice() external view returns (uint256 price);
  
}