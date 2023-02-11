// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { LS1Types } from '../lib/LS1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1Roles } from './LS1Roles.sol';


/**
 * @title LS1EpochSchedule
 * @author MarginX
 *
 * @dev Defines a function from block timestamp to epoch number.
 *
 *  The formula used is `n = floor((t - b) / a)` where:
 *    - `n` is the epoch number
 *    - `t` is the timestamp (in seconds)
 *    - `b` is a non-negative offset, indicating the start of epoch zero (in seconds)
 *    - `a` is the length of an epoch, a.k.a. the interval (in seconds)
 *
 *  Note that by restricting `b` to be non-negative, we limit ourselves to functions in which epoch
 *  zero starts at a non-negative timestamp.
 *
 *  The recommended epoch length and blackout window are 28 and 7 days respectively; however, these
 *  are modifiable by the admin, within the specified bounds.
 */
abstract contract LS1EpochSchedule is
  LS1Roles
{
  using SafeCast for uint256;
  using SafeMathUpgradeable for uint256;

  // ============ Constants ============

  /// @dev Minimum blackout window. Note: The min epoch length is twice the current blackout window.
  //uint256 private constant MIN_BLACKOUT_WINDOW = 3 days;
  uint256 private constant MIN_BLACKOUT_WINDOW = 1 minutes;

  /// @dev Maximum epoch length. Note: The max blackout window is half the current epoch length.
  uint256 private constant MAX_EPOCH_LENGTH = 92 days; // Approximately one quarter year.

  // ============ Events ============

  event EpochParametersChanged(
    LS1Types.EpochParameters epochParameters
  );

  event BlackoutWindowChanged(
    uint256 blackoutWindow
  );

  // ============ Initializer ============

  function __LS1EpochSchedule_init(
    uint256 interval,
    uint256 offset,
    uint256 blackoutWindow
  )
    internal
  {
    require(
      block.timestamp < offset,
      'Epoch zero must be in future'
    );

    // Don't use _setBlackoutWindow() since the interval is not set yet and validation would fail.
    _BLACKOUT_WINDOW_ = blackoutWindow;
    emit BlackoutWindowChanged(blackoutWindow);

    _setEpochParameters(interval, offset);
  }

  // ============ Public Functions ============

  /**
   * @notice Get the epoch at the current block timestamp.
   *
   *  NOTE: Reverts if epoch zero has not started.
   *
   * @return The current epoch number.
   */
  function getCurrentEpoch()
    public
    view
    returns (uint256)
  {
    (uint256 interval, uint256 offsetTimestamp) = _getIntervalAndOffsetTimestamp();
    return offsetTimestamp.div(interval);
  }

  /**
   * @notice Get the time remaining in the current epoch.
   *
   *  NOTE: Reverts if epoch zero has not started.
   *
   * @return The number of seconds until the next epoch.
   */
  function getTimeRemainingInCurrentEpoch()
    public
    view
    returns (uint256)
  {
    (uint256 interval, uint256 offsetTimestamp) = _getIntervalAndOffsetTimestamp();
    uint256 timeElapsedInEpoch = offsetTimestamp.mod(interval);
    return interval.sub(timeElapsedInEpoch);
  }

  /**
   * @notice Given an epoch number, get the start of that epoch. Calculated as `t = (n * a) + b`.
   *
   * @return The timestamp in seconds representing the start of that epoch.
   */
  function getStartOfEpoch(
    uint256 epochNumber
  )
    public
    view
    returns (uint256)
  {
    LS1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;
    uint256 interval = uint256(epochParameters.interval);
    uint256 offset = uint256(epochParameters.offset);
    return epochNumber.mul(interval).add(offset);
  }

  /**
   * @notice Check whether we are at or past the start of epoch zero.
   *
   * @return Boolean `true` if the current timestamp is at least the start of epoch zero,
   *  otherwise `false`.
   */
  function hasEpochZeroStarted()
    public
    view
    returns (bool)
  {
    LS1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;
    uint256 offset = uint256(epochParameters.offset);
    return block.timestamp >= offset;
  }

  /**
   * @notice Check whether we are in a blackout window, where withdrawal requests are restricted.
   *  Note that before epoch zero has started, there are no blackout windows.
   *
   * @return Boolean `true` if we are in a blackout window, otherwise `false`.
   */
  function inBlackoutWindow()
    public
    view
    returns (bool)
  {
    return hasEpochZeroStarted() && getTimeRemainingInCurrentEpoch() <= _BLACKOUT_WINDOW_;
  }

  // ============ Internal Functions ============

  function _setEpochParameters(
    uint256 interval,
    uint256 offset
  )
    internal
  {
    _validateParamLengths(interval, _BLACKOUT_WINDOW_);
    LS1Types.EpochParameters memory epochParameters =
      LS1Types.EpochParameters({interval: interval.toUint128(), offset: offset.toUint128()});
    _EPOCH_PARAMETERS_ = epochParameters;
    emit EpochParametersChanged(epochParameters);
  }

  function _setBlackoutWindow(
    uint256 blackoutWindow
  )
    internal
  {
    _validateParamLengths(uint256(_EPOCH_PARAMETERS_.interval), blackoutWindow);
    _BLACKOUT_WINDOW_ = blackoutWindow;
    emit BlackoutWindowChanged(blackoutWindow);
  }

  // ============ Private Functions ============

  /**
   * @dev Helper function to read params from storage and apply offset to the given timestamp.
   *
   *  NOTE: Reverts if epoch zero has not started.
   *
   * @return The length of an epoch, in seconds.
   * @return The start of epoch zero, in seconds.
   */
  function _getIntervalAndOffsetTimestamp()
    private
    view
    returns (uint256, uint256)
  {
    LS1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;
    uint256 interval = uint256(epochParameters.interval);
    uint256 offset = uint256(epochParameters.offset);

    require(block.timestamp >= offset, 'Ep0 not started');

    uint256 offsetTimestamp = block.timestamp.sub(offset);
    return (interval, offsetTimestamp);
  }

  /**
   * @dev Helper for common validation: verify that the interval and window lengths are valid.
   */
  function _validateParamLengths(
    uint256 interval,
    uint256 blackoutWindow
  )
    private
    pure
  {
    require(
      blackoutWindow.mul(2) <= interval,
      'B.O window <= 1/2 ep length'
    );
    require(
      blackoutWindow >= MIN_BLACKOUT_WINDOW,
      'B.O window < Min'
    );
    require(
      interval <= MAX_EPOCH_LENGTH,
      'Ep length > Max'
    );
  }
}