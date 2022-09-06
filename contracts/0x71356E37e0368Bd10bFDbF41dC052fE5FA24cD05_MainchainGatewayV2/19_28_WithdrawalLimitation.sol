// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GatewayV2.sol";

abstract contract WithdrawalLimitation is GatewayV2 {
  /// @dev Emitted when the high-tier vote weight threshold is updated
  event HighTierVoteWeightThresholdUpdated(
    uint256 indexed nonce,
    uint256 indexed numerator,
    uint256 indexed denominator,
    uint256 previousNumerator,
    uint256 previousDenominator
  );
  /// @dev Emitted when the thresholds for high-tier withdrawals that requires high-tier vote weights are updated
  event HighTierThresholdsUpdated(address[] tokens, uint256[] thresholds);
  /// @dev Emitted when the thresholds for locked withdrawals are updated
  event LockedThresholdsUpdated(address[] tokens, uint256[] thresholds);
  /// @dev Emitted when the fee percentages to unlock withdraw are updated
  event UnlockFeePercentagesUpdated(address[] tokens, uint256[] percentages);
  /// @dev Emitted when the daily limit thresholds are updated
  event DailyWithdrawalLimitsUpdated(address[] tokens, uint256[] limits);

  uint256 public constant _MAX_PERCENTAGE = 1_000_000;

  uint256 internal _highTierVWNum;
  uint256 internal _highTierVWDenom;

  /// @dev Mapping from mainchain token => the amount thresholds for high-tier withdrawals that requires high-tier vote weights
  mapping(address => uint256) public highTierThreshold;
  /// @dev Mapping from mainchain token => the amount thresholds to lock withdrawal
  mapping(address => uint256) public lockedThreshold;
  /// @dev Mapping from mainchain token => unlock fee percentages for unlocker
  /// @notice Values 0-1,000,000 map to 0%-100%
  mapping(address => uint256) public unlockFeePercentages;
  /// @dev Mapping from mainchain token => daily limit amount for withdrawal
  mapping(address => uint256) public dailyWithdrawalLimit;
  /// @dev Mapping from token address => today withdrawal amount
  mapping(address => uint256) public lastSyncedWithdrawal;
  /// @dev Mapping from token address => last date synced to record the `lastSyncedWithdrawal`
  mapping(address => uint256) public lastDateSynced;

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   */
  uint256[50] private ______gap;

  /**
   * @dev Override {GatewayV2-setThreshold}.
   *
   * Requirements:
   * - The high-tier vote weight threshold must equal to or larger than the normal threshold.
   *
   */
  function setThreshold(uint256 _numerator, uint256 _denominator)
    external
    virtual
    override
    onlyAdmin
    returns (uint256 _previousNum, uint256 _previousDenom)
  {
    (_previousNum, _previousDenom) = _setThreshold(_numerator, _denominator);
    _verifyThresholds();
  }

  /**
   * @dev Returns the high-tier vote weight threshold.
   */
  function getHighTierVoteWeightThreshold() external view virtual returns (uint256, uint256) {
    return (_highTierVWNum, _highTierVWDenom);
  }

  /**
   * @dev Checks whether the `_voteWeight` passes the high-tier vote weight threshold.
   */
  function checkHighTierVoteWeightThreshold(uint256 _voteWeight) external view virtual returns (bool) {
    return _voteWeight * _highTierVWDenom >= _highTierVWNum * validatorContract.totalWeights();
  }

  /**
   * @dev Sets high-tier vote weight threshold and returns the old one.
   *
   * Requirements:
   * - The method caller is admin.
   * - The high-tier vote weight threshold must equal to or larger than the normal threshold.
   *
   * Emits the `HighTierVoteWeightThresholdUpdated` event.
   *
   */
  function setHighTierVoteWeightThreshold(uint256 _numerator, uint256 _denominator)
    external
    virtual
    onlyAdmin
    returns (uint256 _previousNum, uint256 _previousDenom)
  {
    (_previousNum, _previousDenom) = _setHighTierVoteWeightThreshold(_numerator, _denominator);
    _verifyThresholds();
  }

  /**
   * @dev Sets the thresholds for high-tier withdrawals that requires high-tier vote weights.
   *
   * Requirements:
   * - The method caller is admin.
   * - The arrays have the same length and its length larger than 0.
   *
   * Emits the `HighTierThresholdsUpdated` event.
   *
   */
  function setHighTierThresholds(address[] calldata _tokens, uint256[] calldata _thresholds)
    external
    virtual
    onlyAdmin
  {
    require(_tokens.length > 0, "WithdrawalLimitation: invalid array length");
    _setHighTierThresholds(_tokens, _thresholds);
  }

  /**
   * @dev Sets the amount thresholds to lock withdrawal.
   *
   * Requirements:
   * - The method caller is admin.
   * - The arrays have the same length and its length larger than 0.
   *
   * Emits the `LockedThresholdsUpdated` event.
   *
   */
  function setLockedThresholds(address[] calldata _tokens, uint256[] calldata _thresholds) external virtual onlyAdmin {
    require(_tokens.length > 0, "WithdrawalLimitation: invalid array length");
    _setLockedThresholds(_tokens, _thresholds);
  }

  /**
   * @dev Sets fee percentages to unlock withdrawal.
   *
   * Requirements:
   * - The method caller is admin.
   * - The arrays have the same length and its length larger than 0.
   *
   * Emits the `UnlockFeePercentagesUpdated` event.
   *
   */
  function setUnlockFeePercentages(address[] calldata _tokens, uint256[] calldata _percentages)
    external
    virtual
    onlyAdmin
  {
    require(_tokens.length > 0, "WithdrawalLimitation: invalid array length");
    _setUnlockFeePercentages(_tokens, _percentages);
  }

  /**
   * @dev Sets daily limit amounts for the withdrawals.
   *
   * Requirements:
   * - The method caller is admin.
   * - The arrays have the same length and its length larger than 0.
   *
   * Emits the `DailyWithdrawalLimitsUpdated` event.
   *
   */
  function setDailyWithdrawalLimits(address[] calldata _tokens, uint256[] calldata _limits) external virtual onlyAdmin {
    require(_tokens.length > 0, "WithdrawalLimitation: invalid array length");
    _setDailyWithdrawalLimits(_tokens, _limits);
  }

  /**
   * @dev Checks whether the withdrawal reaches the limitation.
   */
  function reachedWithdrawalLimit(address _token, uint256 _quantity) external view virtual returns (bool) {
    return _reachedWithdrawalLimit(_token, _quantity);
  }

  /**
   * @dev Sets high-tier vote weight threshold and returns the old one.
   *
   * Emits the `HighTierVoteWeightThresholdUpdated` event.
   *
   */
  function _setHighTierVoteWeightThreshold(uint256 _numerator, uint256 _denominator)
    internal
    returns (uint256 _previousNum, uint256 _previousDenom)
  {
    require(_numerator <= _denominator, "WithdrawalLimitation: invalid threshold");
    _previousNum = _highTierVWNum;
    _previousDenom = _highTierVWDenom;
    _highTierVWNum = _numerator;
    _highTierVWDenom = _denominator;
    emit HighTierVoteWeightThresholdUpdated(nonce++, _numerator, _denominator, _previousNum, _previousDenom);
  }

  /**
   * @dev Sets the thresholds for high-tier withdrawals that requires high-tier vote weights.
   *
   * Requirements:
   * - The array lengths are equal.
   *
   * Emits the `HighTierThresholdsUpdated` event.
   *
   */
  function _setHighTierThresholds(address[] calldata _tokens, uint256[] calldata _thresholds) internal virtual {
    require(_tokens.length == _thresholds.length, "WithdrawalLimitation: invalid array length");
    for (uint256 _i; _i < _tokens.length; _i++) {
      highTierThreshold[_tokens[_i]] = _thresholds[_i];
    }
    emit HighTierThresholdsUpdated(_tokens, _thresholds);
  }

  /**
   * @dev Sets the amount thresholds to lock withdrawal.
   *
   * Requirements:
   * - The array lengths are equal.
   *
   * Emits the `LockedThresholdsUpdated` event.
   *
   */
  function _setLockedThresholds(address[] calldata _tokens, uint256[] calldata _thresholds) internal virtual {
    require(_tokens.length == _thresholds.length, "WithdrawalLimitation: invalid array length");
    for (uint256 _i; _i < _tokens.length; _i++) {
      lockedThreshold[_tokens[_i]] = _thresholds[_i];
    }
    emit LockedThresholdsUpdated(_tokens, _thresholds);
  }

  /**
   * @dev Sets fee percentages to unlock withdrawal.
   *
   * Requirements:
   * - The array lengths are equal.
   * - The percentage is equal to or less than 100_000.
   *
   * Emits the `UnlockFeePercentagesUpdated` event.
   *
   */
  function _setUnlockFeePercentages(address[] calldata _tokens, uint256[] calldata _percentages) internal virtual {
    require(_tokens.length == _percentages.length, "WithdrawalLimitation: invalid array length");
    for (uint256 _i; _i < _tokens.length; _i++) {
      require(_percentages[_i] <= _MAX_PERCENTAGE, "WithdrawalLimitation: invalid percentage");
      unlockFeePercentages[_tokens[_i]] = _percentages[_i];
    }
    emit UnlockFeePercentagesUpdated(_tokens, _percentages);
  }

  /**
   * @dev Sets daily limit amounts for the withdrawals.
   *
   * Requirements:
   * - The array lengths are equal.
   *
   * Emits the `DailyWithdrawalLimitsUpdated` event.
   *
   */
  function _setDailyWithdrawalLimits(address[] calldata _tokens, uint256[] calldata _limits) internal virtual {
    require(_tokens.length == _limits.length, "WithdrawalLimitation: invalid array length");
    for (uint256 _i; _i < _tokens.length; _i++) {
      dailyWithdrawalLimit[_tokens[_i]] = _limits[_i];
    }
    emit DailyWithdrawalLimitsUpdated(_tokens, _limits);
  }

  /**
   * @dev Checks whether the withdrawal reaches the daily limitation.
   *
   * Requirements:
   * - The daily withdrawal threshold should not apply for locked withdrawals.
   *
   */
  function _reachedWithdrawalLimit(address _token, uint256 _quantity) internal view virtual returns (bool) {
    if (_lockedWithdrawalRequest(_token, _quantity)) {
      return false;
    }

    uint256 _currentDate = block.timestamp / 1 days;
    if (_currentDate > lastDateSynced[_token]) {
      return dailyWithdrawalLimit[_token] <= _quantity;
    } else {
      return dailyWithdrawalLimit[_token] <= lastSyncedWithdrawal[_token] + _quantity;
    }
  }

  /**
   * @dev Record withdrawal token.
   */
  function _recordWithdrawal(address _token, uint256 _quantity) internal virtual {
    uint256 _currentDate = block.timestamp / 1 days;
    if (_currentDate > lastDateSynced[_token]) {
      lastDateSynced[_token] = _currentDate;
      lastSyncedWithdrawal[_token] = _quantity;
    } else {
      lastSyncedWithdrawal[_token] += _quantity;
    }
  }

  /**
   * @dev Returns whether the withdrawal request is locked or not.
   */
  function _lockedWithdrawalRequest(address _token, uint256 _quantity) internal view virtual returns (bool) {
    return lockedThreshold[_token] <= _quantity;
  }

  /**
   * @dev Computes fee percentage.
   */
  function _computeFeePercentage(uint256 _amount, uint256 _percentage) internal view virtual returns (uint256) {
    return (_amount * _percentage) / _MAX_PERCENTAGE;
  }

  /**
   * @dev Returns high-tier vote weight.
   */
  function _highTierVoteWeight(uint256 _totalWeight) internal view virtual returns (uint256) {
    return (_highTierVWNum * _totalWeight + _highTierVWDenom - 1) / _highTierVWDenom;
  }

  /**
   * @dev Validates whether the high-tier vote weight threshold is larger than the normal threshold.
   */
  function _verifyThresholds() internal view {
    require(_num * _highTierVWDenom <= _highTierVWNum * _denom, "WithdrawalLimitation: invalid thresholds");
  }
}