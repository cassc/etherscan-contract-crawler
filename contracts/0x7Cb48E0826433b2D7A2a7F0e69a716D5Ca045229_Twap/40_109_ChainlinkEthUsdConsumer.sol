// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IEthUsdOracle.sol";

contract ChainlinkEthUsdConsumer is IEthUsdOracle {
  using SafeMath for uint256;

  /// @dev Number of decimal places in the representations. */
  uint8 private constant AGGREGATOR_DECIMALS = 8;
  uint8 private constant PRICE_DECIMALS = 27;

  uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
    10**uint256(PRICE_DECIMALS - AGGREGATOR_DECIMALS);

  AggregatorV3Interface internal immutable priceFeed;

  /**
   * @notice Construct a new price consumer
   * @dev Source: https://docs.chain.link/docs/ethereum-addresses#config
   */
  constructor(address aggregatorAddress) {
    priceFeed = AggregatorV3Interface(aggregatorAddress);
  }

  /// @inheritdoc IEthUsdOracle
  function consult()
    external
    view
    override(IEthUsdOracle)
    returns (uint256 price)
  {
    (, int256 _price, , , ) = priceFeed.latestRoundData();
    require(_price >= 0, "ChainlinkConsumer/StrangeOracle");
    return (price = uint256(_price).mul(
      UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR
    ));
  }

  /**
   * @notice Retrieves decimals of price feed
   * @dev (`AGGREGATOR_DECIMALS` for ETH-USD by default, scaled up to `PRICE_DECIMALS` here)
   */
  function getDecimals() external pure returns (uint8 decimals) {
    return (decimals = PRICE_DECIMALS);
  }
}