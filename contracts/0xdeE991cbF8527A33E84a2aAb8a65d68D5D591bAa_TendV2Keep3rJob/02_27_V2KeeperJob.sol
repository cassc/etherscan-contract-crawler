// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './utils/GasBaseFee.sol';
import './utils/MachineryReady.sol';
import '../interfaces/IV2KeeperJob.sol';
import '../interfaces/external/IV2Keeper.sol';
import '../interfaces/external/IBaseStrategy.sol';

abstract contract V2KeeperJob is IV2KeeperJob, MachineryReady, GasBaseFee {
  using EnumerableSet for EnumerableSet.AddressSet;
  /// @inheritdoc IV2KeeperJob
  IV2Keeper public v2Keeper;

  EnumerableSet.AddressSet internal _availableStrategies;
  /// @inheritdoc IV2KeeperJob
  mapping(address => uint256) public requiredAmount;
  /// @inheritdoc IV2KeeperJob
  mapping(address => uint256) public lastWorkAt;
  /// @inheritdoc IV2KeeperJob
  uint256 public workCooldown;

  constructor(
    address _governor,
    address _v2Keeper,
    address _mechanicsRegistry,
    uint256 _workCooldown
  ) Governable(_governor) MachineryReady(_mechanicsRegistry) {
    v2Keeper = IV2Keeper(_v2Keeper);
    if (_workCooldown > 0) _setWorkCooldown(_workCooldown);
  }

  // views

  /// @inheritdoc IV2KeeperJob
  function strategies() public view returns (address[] memory _strategies) {
    _strategies = new address[](_availableStrategies.length());
    for (uint256 _i; _i < _availableStrategies.length(); _i++) {
      _strategies[_i] = _availableStrategies.at(_i);
    }
  }

  // setters

  /// @inheritdoc IV2KeeperJob
  function setV2Keeper(address _v2Keeper) external onlyGovernor {
    _setV2Keeper(_v2Keeper);
  }

  /// @inheritdoc IV2KeeperJob
  function setWorkCooldown(uint256 _workCooldown) external onlyGovernorOrMechanic {
    _setWorkCooldown(_workCooldown);
  }

  /// @inheritdoc IV2KeeperJob
  function addStrategy(address _strategy, uint256 _requiredAmount) external onlyGovernorOrMechanic {
    _addStrategy(_strategy, _requiredAmount);
  }

  /// @inheritdoc IV2KeeperJob
  function addStrategies(address[] calldata _strategies, uint256[] calldata _requiredAmounts) external onlyGovernorOrMechanic {
    if (_strategies.length != _requiredAmounts.length) revert WrongLengths();
    for (uint256 _i; _i < _strategies.length; _i++) {
      _addStrategy(_strategies[_i], _requiredAmounts[_i]);
    }
  }

  /// @inheritdoc IV2KeeperJob
  function updateRequiredAmount(address _strategy, uint256 _requiredAmount) external onlyGovernorOrMechanic {
    _updateRequiredAmount(_strategy, _requiredAmount);
  }

  /// @inheritdoc IV2KeeperJob
  function updateRequiredAmounts(address[] calldata _strategies, uint256[] calldata _requiredAmounts) external onlyGovernorOrMechanic {
    if (_strategies.length != _requiredAmounts.length) revert WrongLengths();
    for (uint256 _i; _i < _strategies.length; _i++) {
      _updateRequiredAmount(_strategies[_i], _requiredAmounts[_i]);
    }
  }

  /// @inheritdoc IV2KeeperJob
  function removeStrategy(address _strategy) external onlyGovernorOrMechanic {
    _removeStrategy(_strategy);
  }

  // internals

  function _setV2Keeper(address _v2Keeper) internal {
    v2Keeper = IV2Keeper(_v2Keeper);
  }

  function _setWorkCooldown(uint256 _workCooldown) internal {
    if (_workCooldown == 0) revert ZeroCooldown();
    workCooldown = _workCooldown;
  }

  function _addStrategy(address _strategy, uint256 _requiredAmount) internal {
    if (_availableStrategies.contains(_strategy)) revert StrategyAlreadyAdded();
    _setRequiredAmount(_strategy, _requiredAmount);
    emit StrategyAdded(_strategy, _requiredAmount);
    _availableStrategies.add(_strategy);
  }

  function _updateRequiredAmount(address _strategy, uint256 _requiredAmount) internal {
    if (!_availableStrategies.contains(_strategy)) revert StrategyNotAdded();
    _setRequiredAmount(_strategy, _requiredAmount);
    emit StrategyModified(_strategy, _requiredAmount);
  }

  function _removeStrategy(address _strategy) internal {
    if (!_availableStrategies.contains(_strategy)) revert StrategyNotAdded();
    delete requiredAmount[_strategy];
    _availableStrategies.remove(_strategy);
    emit StrategyRemoved(_strategy);
  }

  function _setRequiredAmount(address _strategy, uint256 _requiredAmount) internal {
    requiredAmount[_strategy] = _requiredAmount;
  }

  function _workable(address _strategy) internal view virtual returns (bool) {
    if (!_availableStrategies.contains(_strategy)) revert StrategyNotAdded();
    if (workCooldown == 0 || block.timestamp > lastWorkAt[_strategy] + workCooldown) return true;
    return false;
  }

  function _getCallCosts(address _strategy) internal view returns (uint256 _callCost) {
    uint256 _gasAmount = requiredAmount[_strategy];
    if (_gasAmount == 0) return 0;
    return _gasAmount * _gasPrice();
  }

  function _workInternal(address _strategy) internal {
    if (!_workable(_strategy)) revert StrategyNotWorkable();
    lastWorkAt[_strategy] = block.timestamp;
    _work(_strategy);
    emit KeeperWorked(_strategy);
  }

  function _forceWork(address _strategy) internal {
    _work(_strategy);
    emit ForceWorked(_strategy);
  }

  /// @dev This function should be implemented on the base contract
  function _work(address _strategy) internal virtual {}
}