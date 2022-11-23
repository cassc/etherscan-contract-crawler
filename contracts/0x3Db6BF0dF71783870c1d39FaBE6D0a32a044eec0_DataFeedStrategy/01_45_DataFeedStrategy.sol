//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {Governable} from './peripherals/Governable.sol';
import {IDataFeedStrategy, IUniswapV3Pool, IDataFeed, IBridgeSenderAdapter, IOracleSidechain} from '../interfaces/IDataFeedStrategy.sol';
import {Create2Address} from '../libraries/Create2Address.sol';

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
  uint24 public twapThreshold;

  /// @inheritdoc IDataFeedStrategy
  uint32 public twapLength;

  address internal constant _UNISWAP_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
  bytes32 internal constant _POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

  constructor(
    address _governor,
    IDataFeed _dataFeed,
    StrategySettings memory _params
  ) Governable(_governor) {
    dataFeed = _dataFeed;
    _setStrategyCooldown(_params.cooldown);
    _setTwapLength(_params.twapLength);
    _setTwapThreshold(_params.twapThreshold);
    _setPeriodDuration(_params.periodDuration);
  }

  /// @inheritdoc IDataFeedStrategy
  function strategicFetchObservations(bytes32 _poolSalt, TriggerReason _reason) external {
    IDataFeed.PoolState memory _lastPoolStateObserved;
    (, _lastPoolStateObserved.blockTimestamp, _lastPoolStateObserved.tickCumulative, _lastPoolStateObserved.arithmeticMeanTick) = dataFeed
      .lastPoolStateObserved(_poolSalt);
    if (!_isStrategic(_poolSalt, _lastPoolStateObserved, _reason)) revert NotStrategic();
    uint32[] memory _secondsAgos = calculateSecondsAgos(_lastPoolStateObserved.blockTimestamp);
    dataFeed.fetchObservations(_poolSalt, _secondsAgos);
    emit StrategicFetch(_poolSalt, _reason);
  }

  /// @inheritdoc IDataFeedStrategy
  /// @dev Allows governor to choose a timestamp from which to send data (overcome !OLD error)
  function forceFetchObservations(bytes32 _poolSalt, uint32 _fromTimestamp) external onlyGovernor {
    uint32[] memory _secondsAgos = calculateSecondsAgos(_fromTimestamp);
    dataFeed.fetchObservations(_poolSalt, _secondsAgos);
  }

  /// @inheritdoc IDataFeedStrategy
  function setStrategyCooldown(uint32 _strategyCooldown) external onlyGovernor {
    _setStrategyCooldown(_strategyCooldown);
  }

  /// @inheritdoc IDataFeedStrategy
  function setTwapLength(uint32 _twapLength) external onlyGovernor {
    _setTwapLength(_twapLength);
  }

  /// @inheritdoc IDataFeedStrategy
  function setTwapThreshold(uint24 _twapThreshold) external onlyGovernor {
    _setTwapThreshold(_twapThreshold);
  }

  /// @inheritdoc IDataFeedStrategy
  function setPeriodDuration(uint32 _periodDuration) external onlyGovernor {
    _setPeriodDuration(_periodDuration);
  }

  /// @inheritdoc IDataFeedStrategy
  function isStrategic(bytes32 _poolSalt) external view returns (TriggerReason _reason) {
    if (isStrategic(_poolSalt, TriggerReason.TIME)) return TriggerReason.TIME;
    if (isStrategic(_poolSalt, TriggerReason.TWAP)) return TriggerReason.TWAP;
  }

  /// @inheritdoc IDataFeedStrategy
  function isStrategic(bytes32 _poolSalt, TriggerReason _reason) public view returns (bool _strategic) {
    IDataFeed.PoolState memory _lastPoolStateObserved;
    (, _lastPoolStateObserved.blockTimestamp, _lastPoolStateObserved.tickCumulative, _lastPoolStateObserved.arithmeticMeanTick) = dataFeed
      .lastPoolStateObserved(_poolSalt);
    return _isStrategic(_poolSalt, _lastPoolStateObserved, _reason);
  }

  /// @inheritdoc IDataFeedStrategy
  function calculateSecondsAgos(uint32 _fromTimestamp) public view returns (uint32[] memory _secondsAgos) {
    if (_fromTimestamp == 0) return _initializeSecondsAgos();
    uint32 _secondsNow = uint32(block.timestamp); // truncation is desired
    uint32 _timeSinceLastObservation = _secondsNow - _fromTimestamp;
    uint32 _periodDuration = periodDuration;
    uint32 _periods = _timeSinceLastObservation / _periodDuration;
    uint32 _remainder = _timeSinceLastObservation % _periodDuration;
    uint32 _i;

    if (_remainder != 0) {
      _secondsAgos = new uint32[](++_periods);
      _timeSinceLastObservation -= _remainder;
      _secondsAgos[_i++] = _timeSinceLastObservation;
    } else {
      _secondsAgos = new uint32[](_periods);
    }

    while (_timeSinceLastObservation > 0) {
      _timeSinceLastObservation -= _periodDuration;
      _secondsAgos[_i++] = _timeSinceLastObservation;
    }
  }

  function _isStrategic(
    bytes32 _poolSalt,
    IDataFeed.PoolState memory _lastPoolStateObserved,
    TriggerReason _reason
  ) internal view returns (bool _strategic) {
    uint32 _secondsNow = uint32(block.timestamp); // truncation is desired
    if (_reason == TriggerReason.TIME) {
      return _secondsNow >= _lastPoolStateObserved.blockTimestamp + strategyCooldown;
    } else if (_reason == TriggerReason.TWAP) {
      return _twapIsOutOfThresholds(_poolSalt, _lastPoolStateObserved, _secondsNow);
    }
  }

  function _twapIsOutOfThresholds(
    bytes32 _poolSalt,
    IDataFeed.PoolState memory _lastPoolStateObserved,
    uint32 _secondsNow
  ) internal view returns (bool _isOutOfThresholds) {
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

    return
      _poolArithmeticMeanTick > _oracleArithmeticMeanTick + int24(twapThreshold) ||
      _poolArithmeticMeanTick < _oracleArithmeticMeanTick - int24(twapThreshold);
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

  function _initializeSecondsAgos() internal view returns (uint32[] memory _secondsAgos) {
    // TODO: define initialization of _secondsAgos
    _secondsAgos = new uint32[](2);
    _secondsAgos[0] = periodDuration;
    _secondsAgos[1] = 0; // as if _fromTimestamp = _secondsNow - (periodDuration + 1)
  }

  function _setStrategyCooldown(uint32 _strategyCooldown) private {
    if (_strategyCooldown < twapLength) revert WrongSetting();

    strategyCooldown = _strategyCooldown;
    emit StrategyCooldownSet(_strategyCooldown);
  }

  function _setTwapLength(uint32 _twapLength) private {
    if ((_twapLength > strategyCooldown) || (_twapLength < periodDuration)) revert WrongSetting();

    twapLength = _twapLength;
    emit TwapLengthSet(_twapLength);
  }

  function _setTwapThreshold(uint24 _twapThreshold) private {
    twapThreshold = _twapThreshold;
    emit TwapThresholdSet(_twapThreshold);
  }

  function _setPeriodDuration(uint32 _periodDuration) private {
    if (_periodDuration > twapLength) revert WrongSetting();

    periodDuration = _periodDuration;
    emit PeriodDurationSet(_periodDuration);
  }
}