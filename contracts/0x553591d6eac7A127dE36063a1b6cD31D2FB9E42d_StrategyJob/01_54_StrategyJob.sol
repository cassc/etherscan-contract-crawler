//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {Keep3rJob, Governable} from './peripherals/Keep3rJob.sol';
import {IStrategyJob, IDataFeedStrategy, IDataFeed, IBridgeSenderAdapter, IOracleSidechain} from '../interfaces/IStrategyJob.sol';

/// @title The StrategyJob contract
/// @notice Adds a reward layer for triggering fetch and bridge transactions
contract StrategyJob is IStrategyJob, Keep3rJob {
  /// @inheritdoc IStrategyJob
  IDataFeedStrategy public immutable dataFeedStrategy;

  /// @inheritdoc IStrategyJob
  IDataFeed public immutable dataFeed;

  /// @inheritdoc IStrategyJob
  IBridgeSenderAdapter public defaultBridgeSenderAdapter;

  /// @inheritdoc IStrategyJob
  mapping(uint32 => mapping(bytes32 => uint24)) public lastPoolNonceBridged;

  constructor(
    address _governor,
    IDataFeedStrategy _dataFeedStrategy,
    IDataFeed _dataFeed,
    IBridgeSenderAdapter _defaultBridgeSenderAdapter
  ) Governable(_governor) {
    dataFeedStrategy = _dataFeedStrategy;
    dataFeed = _dataFeed;
    _setDefaultBridgeSenderAdapter(_defaultBridgeSenderAdapter);
  }

  /// @inheritdoc IStrategyJob
  function work(
    uint32 _chainId,
    bytes32 _poolSalt,
    uint24 _poolNonce,
    IOracleSidechain.ObservationData[] memory _observationsData
  ) external upkeep {
    // TODO: change criteria for workable (if there's a new nonce, bridge)
    if (!_workable(_chainId, _poolSalt, _poolNonce)) revert NotWorkable();
    lastPoolNonceBridged[_chainId][_poolSalt] = _poolNonce;
    dataFeed.sendObservations(defaultBridgeSenderAdapter, _chainId, _poolSalt, _poolNonce, _observationsData);
  }

  /// @inheritdoc IStrategyJob
  function work(bytes32 _poolSalt, IDataFeedStrategy.TriggerReason _reason) external upkeep {
    dataFeedStrategy.strategicFetchObservations(_poolSalt, _reason);
  }

  /// @inheritdoc IStrategyJob
  function setDefaultBridgeSenderAdapter(IBridgeSenderAdapter _defaultBridgeSenderAdapter) external onlyGovernor {
    _setDefaultBridgeSenderAdapter(_defaultBridgeSenderAdapter);
  }

  /// @inheritdoc IStrategyJob
  function workable(
    uint32 _chainId,
    bytes32 _poolSalt,
    uint24 _poolNonce
  ) public view returns (bool _isWorkable) {
    uint24 _whitelistedNonce = dataFeed.whitelistedNonces(_chainId, _poolSalt);
    if (_whitelistedNonce != 0 && _whitelistedNonce <= _poolNonce) return _workable(_chainId, _poolSalt, _poolNonce);
  }

  /// @inheritdoc IStrategyJob
  function workable(bytes32 _poolSalt) external view returns (IDataFeedStrategy.TriggerReason _reason) {
    if (dataFeed.isWhitelistedPool(_poolSalt)) return dataFeedStrategy.isStrategic(_poolSalt);
  }

  /// @inheritdoc IStrategyJob
  function workable(bytes32 _poolSalt, IDataFeedStrategy.TriggerReason _reason) public view returns (bool _isWorkable) {
    if (dataFeed.isWhitelistedPool(_poolSalt)) return dataFeedStrategy.isStrategic(_poolSalt, _reason);
  }

  function _workable(
    uint32 _chainId,
    bytes32 _poolSalt,
    uint24 _poolNonce
  ) internal view returns (bool _isWorkable) {
    uint24 _lastPoolNonceBridged = lastPoolNonceBridged[_chainId][_poolSalt];
    if (_lastPoolNonceBridged == 0) {
      (uint24 _lastPoolNonceObserved, , , ) = dataFeed.lastPoolStateObserved(_poolSalt);
      return _poolNonce == _lastPoolNonceObserved;
    } else {
      return _poolNonce == ++_lastPoolNonceBridged;
    }
  }

  function _setDefaultBridgeSenderAdapter(IBridgeSenderAdapter _defaultBridgeSenderAdapter) private {
    defaultBridgeSenderAdapter = _defaultBridgeSenderAdapter;
    emit DefaultBridgeSenderAdapterSet(_defaultBridgeSenderAdapter);
  }
}