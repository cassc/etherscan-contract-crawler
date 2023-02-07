//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {Governable} from '@defi-wonderland/solidity-utils/solidity/contracts/Governable.sol';
import {IDataFeedStrategy, IUniswapV3Pool, IDataFeed, IBridgeSenderAdapter, IOracleSidechain} from '../interfaces/IDataFeedStrategy.sol';
import {OracleLibrary} from '@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol';
import {Create2Address} from '@defi-wonderland/solidity-utils/solidity/libraries/Create2Address.sol';

/// @title The DataFeed Strategy contract
/// @notice Handles when and how a history of a pool should be updated
contract DataFeedStrategy is IDataFeedStrategy, Governable {
  /// @inheritdoc IDataFeedStrategy
  IDataFeed public immutable dataFeed;

  /// @inheritdoc IDataFeedStrategy
  uint32 public periodDuration;

  /// @inheritdoc IDataFeedStrategy
  uint32 public strategyCooldown;

  /// @inheritdoc IDataFeedStrategy
  uint24 public defaultTwapThreshold;

  mapping(bytes32 => uint24) internal _twapThreshold;

  /// @inheritdoc IDataFeedStrategy
  uint32 public twapLength;

  address internal constant _UNISWAP_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
  bytes32 internal constant _POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

  constructor(
    address _governor,
    IDataFeed _dataFeed,
    StrategySettings memory _params
  ) Governable(_governor) {
    if (address(_dataFeed) == address(0)) revert ZeroAddress();
    dataFeed = _dataFeed;
    _setStrategyCooldown(_params.strategyCooldown);
    _setDefaultTwapThreshold(_params.defaultTwapThreshold);
    _setTwapLength(_params.twapLength);
    _setPeriodDuration(_params.periodDuration);
  }

  /// @inheritdoc IDataFeedStrategy
  function strategicFetchObservations(bytes32 _poolSalt, TriggerReason _reason) external {
    uint32 _secondsNow = uint32(block.timestamp); // truncation is desired
    uint32 _fromSecondsAgo;
    IDataFeed.PoolState memory _lastPoolStateObserved;
    (, _lastPoolStateObserved.blockTimestamp, _lastPoolStateObserved.tickCumulative, _lastPoolStateObserved.arithmeticMeanTick) = dataFeed
      .lastPoolStateObserved(_poolSalt);

    if (_reason == TriggerReason.OLD) {
      uint32 _timeSinceLastObservation = _secondsNow - _lastPoolStateObserved.blockTimestamp;
      uint32 _poolOldestSecondsAgo = _getPoolOldestSecondsAgo(_poolSalt);
      if (!(_timeSinceLastObservation > _poolOldestSecondsAgo)) revert NotStrategic();
      _fromSecondsAgo = _poolOldestSecondsAgo;
    } else {
      if (!_isStrategic(_poolSalt, _lastPoolStateObserved, _reason)) revert NotStrategic();
      _fromSecondsAgo = _secondsNow - _lastPoolStateObserved.blockTimestamp;
    }

    uint32[] memory _secondsAgos = calculateSecondsAgos(_fromSecondsAgo);
    dataFeed.fetchObservations(_poolSalt, _secondsAgos);
    emit StrategicFetch(_poolSalt, _reason);
  }

  /// @inheritdoc IDataFeedStrategy
  function setStrategyCooldown(uint32 _strategyCooldown) external onlyGovernor {
    _setStrategyCooldown(_strategyCooldown);
  }

  /// @inheritdoc IDataFeedStrategy
  function setDefaultTwapThreshold(uint24 _defaultTwapThreshold) external onlyGovernor {
    _setDefaultTwapThreshold(_defaultTwapThreshold);
  }

  /// @inheritdoc IDataFeedStrategy
  function setTwapThreshold(bytes32 _poolSalt, uint24 _poolTwapThreshold) external onlyGovernor {
    _setTwapThreshold(_poolSalt, _poolTwapThreshold);
  }

  /// @inheritdoc IDataFeedStrategy
  function setTwapLength(uint32 _twapLength) external onlyGovernor {
    _setTwapLength(_twapLength);
  }

  /// @inheritdoc IDataFeedStrategy
  function setPeriodDuration(uint32 _periodDuration) external onlyGovernor {
    _setPeriodDuration(_periodDuration);
  }

  /// @inheritdoc IDataFeedStrategy
  function twapThreshold(bytes32 _poolSalt) external view returns (uint24 _poolTwapThreshold) {
    _poolTwapThreshold = _twapThreshold[_poolSalt];
    if (_poolTwapThreshold == 0) return defaultTwapThreshold;
  }

  /// @inheritdoc IDataFeedStrategy
  function isStrategic(bytes32 _poolSalt) external view returns (TriggerReason _reason) {
    if (isStrategic(_poolSalt, TriggerReason.TIME)) return TriggerReason.TIME;
    if (isStrategic(_poolSalt, TriggerReason.TWAP)) return TriggerReason.TWAP;
    if (isStrategic(_poolSalt, TriggerReason.OLD)) return TriggerReason.OLD;
  }

  /// @inheritdoc IDataFeedStrategy
  function isStrategic(bytes32 _poolSalt, TriggerReason _reason) public view returns (bool _strategic) {
    IDataFeed.PoolState memory _lastPoolStateObserved;
    (, _lastPoolStateObserved.blockTimestamp, _lastPoolStateObserved.tickCumulative, _lastPoolStateObserved.arithmeticMeanTick) = dataFeed
      .lastPoolStateObserved(_poolSalt);
    return _isStrategic(_poolSalt, _lastPoolStateObserved, _reason);
  }

  /// @inheritdoc IDataFeedStrategy
  function calculateSecondsAgos(uint32 _fromSecondsAgo) public view returns (uint32[] memory _secondsAgos) {
    uint32 _secondsNow = uint32(block.timestamp); // truncation is desired
    if (_fromSecondsAgo == _secondsNow) return _initializeSecondsAgos();

    uint32 _periodDuration = periodDuration;
    uint32 _maxPeriods = strategyCooldown / _periodDuration;
    uint32 _periods = _fromSecondsAgo / _periodDuration;
    uint32 _remainder = _fromSecondsAgo % _periodDuration;
    uint32 _i;

    if (_periods > _maxPeriods) {
      _remainder += (_periods - _maxPeriods) * _periodDuration;
      _periods = _maxPeriods;
    }

    if (_remainder != 0) {
      _secondsAgos = new uint32[](++_periods);
      _fromSecondsAgo -= _remainder;
      _secondsAgos[_i++] = _fromSecondsAgo;
    } else {
      _secondsAgos = new uint32[](_periods);
    }

    while (_fromSecondsAgo > 0) {
      _fromSecondsAgo -= _periodDuration;
      _secondsAgos[_i++] = _fromSecondsAgo;
    }
  }

  function _isStrategic(
    bytes32 _poolSalt,
    IDataFeed.PoolState memory _lastPoolStateObserved,
    TriggerReason _reason
  ) internal view returns (bool _strategic) {
    if (_reason == TriggerReason.TIME) {
      uint32 _secondsNow = uint32(block.timestamp); // truncation is desired
      return _secondsNow >= _lastPoolStateObserved.blockTimestamp + strategyCooldown;
    } else if (_reason == TriggerReason.TWAP) {
      return _twapIsOutOfThresholds(_poolSalt, _lastPoolStateObserved);
    } else if (_reason == TriggerReason.OLD) {
      uint32 _secondsNow = uint32(block.timestamp); // truncation is desired
      uint32 _timeSinceLastObservation = _secondsNow - _lastPoolStateObserved.blockTimestamp;
      uint32 _poolOldestSecondsAgo = _getPoolOldestSecondsAgo(_poolSalt);
      return _timeSinceLastObservation > _poolOldestSecondsAgo;
    }
  }

  function _twapIsOutOfThresholds(bytes32 _poolSalt, IDataFeed.PoolState memory _lastPoolStateObserved)
    internal
    view
    returns (bool _isOutOfThresholds)
  {
    uint32 _secondsNow = uint32(block.timestamp); // truncation is desired
    uint32 _twapLength = twapLength;

    uint32[] memory _secondsAgos = new uint32[](2);
    _secondsAgos[0] = _twapLength;
    _secondsAgos[1] = 0;

    IUniswapV3Pool _pool = IUniswapV3Pool(Create2Address.computeAddress(_UNISWAP_FACTORY, _poolSalt, _POOL_INIT_CODE_HASH));
    (int56[] memory _poolTickCumulatives, ) = _pool.observe(_secondsAgos);

    int24 _poolArithmeticMeanTick = _computeTwap(_poolTickCumulatives[0], _poolTickCumulatives[1], _twapLength);

    uint32 _oracleDelta = _secondsNow - _lastPoolStateObserved.blockTimestamp;
    int56 _oracleTickCumulative = _lastPoolStateObserved.tickCumulative + int56(_lastPoolStateObserved.arithmeticMeanTick) * int32(_oracleDelta);

    int24 _oracleArithmeticMeanTick = _computeTwap(_poolTickCumulatives[0], _oracleTickCumulative, _twapLength);

    uint24 _poolTwapThreshold = _twapThreshold[_poolSalt];
    if (_poolTwapThreshold == 0) _poolTwapThreshold = defaultTwapThreshold;

    return
      _poolArithmeticMeanTick > _oracleArithmeticMeanTick + int24(_poolTwapThreshold) ||
      _poolArithmeticMeanTick < _oracleArithmeticMeanTick - int24(_poolTwapThreshold);
  }

  function _computeTwap(
    int56 _tickCumulative1,
    int56 _tickCumulative2,
    uint32 _delta
  ) internal pure returns (int24 _arithmeticMeanTick) {
    int56 _tickCumulativesDelta = _tickCumulative2 - _tickCumulative1;
    _arithmeticMeanTick = int24(_tickCumulativesDelta / int32(_delta));
    // Always round to negative infinity
    if (_tickCumulativesDelta < 0 && (_tickCumulativesDelta % int32(_delta) != 0)) --_arithmeticMeanTick;
  }

  function _getPoolOldestSecondsAgo(bytes32 _poolSalt) internal view returns (uint32 _poolOldestSecondsAgo) {
    IUniswapV3Pool _pool = IUniswapV3Pool(Create2Address.computeAddress(_UNISWAP_FACTORY, _poolSalt, _POOL_INIT_CODE_HASH));
    _poolOldestSecondsAgo = OracleLibrary.getOldestObservationSecondsAgo(address(_pool));
  }

  function _initializeSecondsAgos() internal view returns (uint32[] memory _secondsAgos) {
    _secondsAgos = new uint32[](2);
    _secondsAgos[0] = periodDuration;
    _secondsAgos[1] = 0;
  }

  function _setStrategyCooldown(uint32 _strategyCooldown) private {
    if (_strategyCooldown < twapLength) revert WrongSetting();

    strategyCooldown = _strategyCooldown;
    emit StrategyCooldownSet(_strategyCooldown);
  }

  function _setDefaultTwapThreshold(uint24 _defaultTwapThreshold) private {
    if (_defaultTwapThreshold == 0) revert ZeroAmount();

    defaultTwapThreshold = _defaultTwapThreshold;
    emit DefaultTwapThresholdSet(_defaultTwapThreshold);
  }

  function _setTwapThreshold(bytes32 _poolSalt, uint24 _poolTwapThreshold) private {
    _twapThreshold[_poolSalt] = _poolTwapThreshold;
    emit TwapThresholdSet(_poolSalt, _poolTwapThreshold);
  }

  function _setTwapLength(uint32 _twapLength) private {
    if ((_twapLength > strategyCooldown) || (_twapLength < periodDuration)) revert WrongSetting();

    twapLength = _twapLength;
    emit TwapLengthSet(_twapLength);
  }

  function _setPeriodDuration(uint32 _periodDuration) private {
    if (_periodDuration > twapLength || _periodDuration == 0) revert WrongSetting();

    periodDuration = _periodDuration;
    emit PeriodDurationSet(_periodDuration);
  }
}