// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
  AggregatorV3Interface
} from '../../../../@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import {ISynthereumPriceFeed} from '../../common/interfaces/IPriceFeed.sol';

interface ISynthereumChainlinkPriceFeed is ISynthereumPriceFeed {
  struct OracleData {
    uint80 roundId;
    uint256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
    uint8 decimals;
  }
  enum Type {STANDARD, INVERSE, COMPUTED}

  /**
   * @notice Set a pair object associated to a price identifier
   * @param _kind Dictates what kind of price identifier is being registered
   * @param _priceIdentifier Price feed identifier of the pair
   * @param _aggregator Address of chainlink proxy aggregator
   * @param _intermediatePairs Price feed identifier of the pairs to use for computed price
   */
  function setPair(
    Type _kind,
    bytes32 _priceIdentifier,
    address _aggregator,
    bytes32[] memory _intermediatePairs
  ) external;

  /**
   * @notice Delete the Pair object associated to a price identifier
   * @param _priceIdentifier Price feed identifier
   */
  function removePair(bytes32 _priceIdentifier) external;

  /**
   * @notice Get last chainlink oracle price of a set of price identifiers
   * @param _priceIdentifiers Array of Price feed identifier
   * @return prices Oracle prices for the ids
   */
  function getLatestPrices(bytes32[] calldata _priceIdentifiers)
    external
    returns (uint256[] memory prices);

  /**
   * @notice Returns the address of aggregator if exists, otherwise it reverts
   * @param _priceIdentifier Price feed identifier
   * @return aggregator Aggregator associated with price identifier
   */
  function getAggregator(bytes32 _priceIdentifier)
    external
    view
    returns (AggregatorV3Interface aggregator);

  /**
   * @notice Get chainlink oracle price in a given round for a given price identifier
   * @param _priceIdentifier Price feed identifier
   * @param _roundId Round Id
   * @return price Oracle price
   */
  function getRoundPrice(bytes32 _priceIdentifier, uint80 _roundId)
    external
    view
    returns (uint256 price);
}