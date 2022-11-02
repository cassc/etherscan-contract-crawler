// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.2;

import "./OracleUpdatableInterface.sol";

/**
 * @title Binance Oracle OnChain
 * @notice OnChain acts as a staging area for price updates before sending them to the aggregators
 * @dev OnChainOracle is responsible for creating and owning aggregators when needed
 * @author Sri Krishna Mannem
 */
interface OnChainOracleInterface {
  /**
   *  @notice Signed batch update request from an authenticated off-chain Oracle
   */
  function putBatch(
    uint256 batchId_,
    bytes calldata message_,
    bytes calldata signature_
  ) external;

  /**
   * @dev Create an aggregator for a pair, replace if already exists
   * @param pair_  the trading pair for which to create an aggregator
   * @param aggregatorAddress  address of the aggregator for the pair
   */
  function addAggregatorForPair(string calldata pair_, OracleUpdatableInterface aggregatorAddress) external;

  /**
   * @param pair_  pair to get address of the aggregator
   * @return address The current mapping of aggregators
   */
  function getAggregatorForPair(string calldata pair_) external returns (address);
}