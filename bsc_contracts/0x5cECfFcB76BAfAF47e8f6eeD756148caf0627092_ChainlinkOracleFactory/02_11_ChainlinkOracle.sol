// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "../interfaces/IOracle.sol";
import "../interfaces/IBEP20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract ChainlinkOracle is IOracle, Initializable {
  AggregatorV3Interface public aggregator;
  uint8 public tokenDecimals;
  uint8 public usdtDecimals;

  constructor() {
    _disableInitializers();
  }

  function initialize(address aggregator_, uint8 tokenDecimals_, uint8 usdtDecimals_) external initializer {
    aggregator = AggregatorV3Interface(aggregator_);
    tokenDecimals = tokenDecimals_;
    usdtDecimals = usdtDecimals_;
  }

  // how many USDT would we get for amount of token
  function price(uint amount) external view override returns (uint256) {
    (, int256 answer,,,) = aggregator.latestRoundData();
    require(answer >= 0, "negative price");
    // amount * answer * 10**(usdtDecimals - aggregator.decimals() - tokenDecimals)
    return (amount * uint(answer) * 10**usdtDecimals) / (10 ** (aggregator.decimals() + tokenDecimals));
  }

  // how many token would we get for an amount of USDT
  function reversePrice(uint amount) external view override returns (uint256) {
    (, int256 answer,,,) = aggregator.latestRoundData();
    require(answer >= 0, "negative price");
    // amount / answer * 10**(aggregator.decimals() + tokenDecimals - usdtDecimals)
    return (amount * 10**(aggregator.decimals() + tokenDecimals)) / (uint(answer) * 10**usdtDecimals);
  }

  function description() external view override returns (string memory) {
    return aggregator.description();
  }
}