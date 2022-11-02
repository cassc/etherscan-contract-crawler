// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.2;

import "./access/SignatureWriteAccessController.sol";
import "./interfaces/OnChainOracleInterface.sol";
import "./access/ECDSA.sol";
import "./interfaces/OracleUpdatableInterface.sol";

/**
 * @title Binance Oracle OnChain implementation
 * @notice OnChain acts as a staging area for price updates before sending them to the aggregators
 * @dev OnChainOracle is responsible for creating and owning aggregators when needed. It has two access controls
 * 1) Give write access control for off-chain nodes using msg.sender
 * 2) Check signature on the putBatch method
 * @author Sri Krishna Mannem
 */
contract OnChainOracle is SignatureWriteAccessController, OnChainOracleInterface {
  using ECDSA for bytes32;

  /// @notice Event with address of the last updater
  event Success(address leaderAddress);
  /// @notice Warn if a certain aggregator is not set
  event AggregatorNotSet(string pairName);

  /// @dev End aggregators to update. We need to create them manually if we add more pairs
  mapping(string => OracleUpdatableInterface) internal aggregators;

  /// @dev Current batchId. OnChain oracle only accepts next request with batchId + 1
  uint256 public batchId;

  /**
   *  @notice Signed batch update request from an authenticated off-chain Oracle
   */
  function putBatch(
    uint256 batchId_,
    bytes calldata message_,
    bytes calldata signature_
  ) external override checkAccess {
    require(batchId_ == batchId + 1, "Unexpected batchId received");

    (address source, uint64 timestamp, string[] memory pairs, int192[] memory prices) = _decodeBatchMessage(
      message_,
      signature_
    );
    require(isSignatureValid(source), "Batch write aborted due to wrong signature");
    require(pairs.length == prices.length, "Pairs and prices have unequal lengths");

    for (uint256 i = 0; i < pairs.length; ++i) {
      if (address(aggregators[pairs[i]]) != address(0)) {
        aggregators[pairs[i]].transmit(timestamp, prices[i]);
      } else {
        emit AggregatorNotSet(pairs[i]);
      }
    }
    batchId++;
    emit Success(msg.sender); //emit already authenticated leader's address
  }

  /**
   * @dev Create an aggregator for a pair, replace if already exists
   * @param pair_  the trading pair for which to create an aggregator
   * @param aggregatorAddress  address of the aggregator for the pair
   */
  function addAggregatorForPair(string calldata pair_, OracleUpdatableInterface aggregatorAddress)
    external
    override
    onlyOwner
  {
    aggregators[pair_] = aggregatorAddress;
  }

  /**
   * Retrieve the current writable aggregator for a pair
   * @param pair_  pair to get address of the aggregator
   * @return aggregator The current mapping of aggregators
   */
  function getAggregatorForPair(string calldata pair_) external view override onlyOwner returns (address) {
    return address(aggregators[pair_]);
  }

  function _decodeBatchMessage(bytes calldata message_, bytes calldata signature_)
    internal
    pure
    returns (
      address,
      uint64,
      string[] memory,
      int192[] memory
    )
  {
    address source = _getSource(message_, signature_);

    // Decode the message and check the version
    (string memory version, uint64 timestamp, string[] memory pairs, int192[] memory prices) = abi.decode(
      message_,
      (string, uint64, string[], int192[])
    );
    require(keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("v1")), "Version of data must be 'v1'");
    return (source, timestamp, pairs, prices);
  }

  /**
   * @dev Recovers the source address which signed a message
   */
  function _getSource(bytes memory message_, bytes memory signature_) internal pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = abi.decode(signature_, (bytes32, bytes32, uint8));
    return keccak256(message_).toEthSignedMessageHash().recover(v, r, s);
  }
}