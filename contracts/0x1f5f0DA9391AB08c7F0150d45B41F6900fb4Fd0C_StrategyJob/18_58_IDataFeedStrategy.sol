//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {IGovernable} from '@defi-wonderland/solidity-utils/solidity/interfaces/IGovernable.sol';
import {IUniswapV3Pool} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import {IDataFeed} from './IDataFeed.sol';
import {IBridgeSenderAdapter} from './bridges/IBridgeSenderAdapter.sol';
import {IOracleSidechain} from '../interfaces/IOracleSidechain.sol';

interface IDataFeedStrategy is IGovernable {
  // ENUMS

  enum TriggerReason {
    NONE,
    TIME,
    TWAP,
    OLD
  }

  // STRUCTS

  struct StrategySettings {
    uint32 periodDuration; // Resolution of the oracle, target twap length
    uint32 strategyCooldown; // Time since last update to wait to time-trigger update
    uint24 defaultTwapThreshold; // Default twap difference, in ticks, to twap-trigger update
    uint32 twapLength; // Twap length, in seconds, used for twap-trigger update
  }

  // STATE VARIABLES

  /// @return _dataFeed The address of the DataFeed contract
  function dataFeed() external view returns (IDataFeed _dataFeed);

  /// @return _periodDuration The targetted amount of seconds between pool consultations
  /// @dev Defines the resolution of the oracle, averaging data between consultations
  function periodDuration() external view returns (uint32 _periodDuration);

  /// @return _strategyCooldown Time in seconds since last update required to time-trigger an update
  function strategyCooldown() external view returns (uint32 _strategyCooldown);

  /// @return _defaultTwapThreshold Default twap difference, in ticks, to twap-trigger an update
  function defaultTwapThreshold() external view returns (uint24 _defaultTwapThreshold);

  /// @param _poolSalt The pool salt defined by token0 token1 and fee
  /// @return _twapThreshold Twap difference, in ticks, to twap-trigger an update
  function twapThreshold(bytes32 _poolSalt) external view returns (uint24 _twapThreshold);

  /// @return _twapLength The time length, in seconds, used to calculate twap-trigger
  function twapLength() external view returns (uint32 _twapLength);

  // EVENTS

  /// @notice Emitted when a data fetch is triggered
  /// @param _poolSalt Identifier of the pool to fetch
  /// @param _reason Identifier number of the reason that triggered the fetch request
  event StrategicFetch(bytes32 indexed _poolSalt, TriggerReason _reason);

  /// @notice Emitted when the owner updates the job cooldown
  /// @param _strategyCooldown The new job cooldown
  event StrategyCooldownSet(uint32 _strategyCooldown);

  /// @notice Emitted when the owner updates the job default twap threshold percentage
  /// @param _defaultTwapThreshold The default twap difference threshold used to trigger an update of the oracle
  event DefaultTwapThresholdSet(uint24 _defaultTwapThreshold);

  /// @notice Emitted when the owner updates the job twap threshold percentage of a pool
  /// @param _poolSalt The pool salt defined by token0 token1 and fee
  /// @param _twapThreshold The default twap difference threshold used to trigger an update of the oracle
  event TwapThresholdSet(bytes32 _poolSalt, uint24 _twapThreshold);

  /// @notice Emitted when the owner updates the job twap length
  /// @param _twapLength The new length of the twap used to trigger an update of the oracle
  event TwapLengthSet(uint32 _twapLength);

  /// @notice Emitted when the owner updates the job period length
  /// @param _periodDuration The new length of reading resolution periods
  event PeriodDurationSet(uint32 _periodDuration);

  // ERRORS

  /// @notice Thrown if the tx is not strategic
  error NotStrategic();

  /// @notice Thrown if setting breaks strategyCooldown >= twapLength >= periodDuration
  error WrongSetting();

  // FUNCTIONS

  /// @notice Permisionless, used to update the oracle state
  /// @param _poolSalt Identifier of the pool to fetch
  /// @param _reason Identifier of trigger reason (time/twap)
  function strategicFetchObservations(bytes32 _poolSalt, TriggerReason _reason) external;

  /// @notice Sets the job cooldown
  /// @param _strategyCooldown The job cooldown to be set
  function setStrategyCooldown(uint32 _strategyCooldown) external;

  /// @notice Sets the job default twap threshold percentage
  /// @param _defaultTwapThreshold The default twap difference threshold used to trigger an update of the oracle
  function setDefaultTwapThreshold(uint24 _defaultTwapThreshold) external;

  /// @notice Sets the job twap threshold percentage of a pool
  /// @param _poolSalt The pool salt defined by token0 token1 and fee
  /// @param _twapThreshold The twap difference threshold used to trigger an update of the oracle
  function setTwapThreshold(bytes32 _poolSalt, uint24 _twapThreshold) external;

  /// @notice Sets the job twap length
  /// @param _twapLength The new length of the twap used to trigger an update of the oracle
  function setTwapLength(uint32 _twapLength) external;

  /// @notice Sets the job period length
  /// @param _periodDuration The new length of reading resolution periods
  function setPeriodDuration(uint32 _periodDuration) external;

  /// @notice Returns if the strategy can be executed
  /// @param _poolSalt The pool salt defined by token0 token1 and fee
  /// @return _reason The reason why the strategy can be executed
  function isStrategic(bytes32 _poolSalt) external view returns (TriggerReason _reason);

  /// @notice Returns if the strategy can be executed
  /// @param _poolSalt The pool salt defined by token0 token1 and fee
  /// @param _reason The reason why the strategy can be executed
  /// @return _isStrategic Whether the tx is strategic or not
  function isStrategic(bytes32 _poolSalt, TriggerReason _reason) external view returns (bool _isStrategic);

  /// @notice Builds the secondsAgos array with periodDuration between each datapoint
  /// @param _fromSecondsAgo Seconds ago of the timestamp from which to backfill the oracle with
  /// @return _secondsAgos Array of secondsAgo that backfills the history from fromSecondsAgo
  function calculateSecondsAgos(uint32 _fromSecondsAgo) external view returns (uint32[] memory _secondsAgos);
}