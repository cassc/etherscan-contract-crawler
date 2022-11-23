//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {IKeep3rJob} from './peripherals/IKeep3rJob.sol';
import {IDataFeedStrategy} from './IDataFeedStrategy.sol';
import {IDataFeed} from './IDataFeed.sol';
import {IBridgeSenderAdapter} from './bridges/IBridgeSenderAdapter.sol';
import {IOracleSidechain} from './IOracleSidechain.sol';

interface IStrategyJob is IKeep3rJob {
  // STATE VARIABLES

  /// @return _dataFeedStrategy The address of the current DataFeedStrategy
  function dataFeedStrategy() external view returns (IDataFeedStrategy _dataFeedStrategy);

  /// @return _dataFeed The address of the DataFeed
  function dataFeed() external view returns (IDataFeed _dataFeed);

  /// @return _defaultBridgeSenderAdapter The address of the job bridge sender adapter
  function defaultBridgeSenderAdapter() external view returns (IBridgeSenderAdapter _defaultBridgeSenderAdapter);

  /// @param _chainId The identifier of the chain
  /// @param _poolSalt The identifier of both the pool and oracle
  /// @return _lastPoolNonceBridged Last nonce of the oracle observed
  function lastPoolNonceBridged(uint32 _chainId, bytes32 _poolSalt) external view returns (uint24 _lastPoolNonceBridged);

  // EVENTS

  /// @notice Emitted when a new default bridge sender adapter is set
  /// @param _defaultBridgeSenderAdapter Address of the new default bridge sender adapter
  event DefaultBridgeSenderAdapterSet(IBridgeSenderAdapter _defaultBridgeSenderAdapter);

  // ERRORS

  /// @notice Thrown when the job is not workable
  error NotWorkable();

  // FUNCTIONS

  /// @notice Calls to send observations in the DataFeed contract
  /// @param _chainId The Ethereum chain identification
  /// @param _poolSalt The pool salt defined by token0 token1 and fee
  /// @param _poolNonce The nonce of the observations fetched by pool
  function work(
    uint32 _chainId,
    bytes32 _poolSalt,
    uint24 _poolNonce,
    IOracleSidechain.ObservationData[] memory _observationsData
  ) external;

  /// @notice Calls to fetch observations and update the oracle state in the DataFeed contract
  /// @param _poolSalt The pool salt defined by token0 token1 and fee
  /// @param _reason The identifier of the reason to trigger an update
  function work(bytes32 _poolSalt, IDataFeedStrategy.TriggerReason _reason) external;

  /// @notice Allows governor to set a new default bridge sender adapter
  /// @param _defaultBridgeSenderAdapter Address of the new default bridge sender adapter
  function setDefaultBridgeSenderAdapter(IBridgeSenderAdapter _defaultBridgeSenderAdapter) external;

  /// @notice Returns if the job can be worked
  /// @param _chainId The destination chain ID
  /// @param _poolSalt The pool salt defined by token0 token1 and fee
  /// @param _poolNonce The nonce of the observations fetched by pool
  /// @return _isWorkable Whether the job is workable or not
  function workable(
    uint32 _chainId,
    bytes32 _poolSalt,
    uint24 _poolNonce
  ) external view returns (bool _isWorkable);

  /// @notice Returns if the job can be worked
  /// @param _poolSalt The pool salt defined by token0 token1 and fee
  /// @return _reason The reason why the job can be worked
  function workable(bytes32 _poolSalt) external view returns (IDataFeedStrategy.TriggerReason _reason);

  /// @notice Returns if the job can be worked
  /// @param _poolSalt The pool salt defined by token0 token1 and fee
  /// @param _reason The reason why the job can be worked
  /// @return _isWorkable Whether the job is workable or not
  function workable(bytes32 _poolSalt, IDataFeedStrategy.TriggerReason _reason) external view returns (bool _isWorkable);
}