// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './utils/GasBaseFee.sol';
import './utils/MachineryReady.sol';
import '../interfaces/IPublicKeeperJob.sol';
import '../interfaces/external/IKeeperWrapper.sol';
import '../interfaces/external/IBaseStrategy.sol';
import '../interfaces/external/IVaultRegistry.sol';
import '../interfaces/external/ITokenVault.sol';

abstract contract PublicKeeperJob is IPublicKeeperJob, MachineryReady, GasBaseFee {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @inheritdoc IPublicKeeperJob
  IKeeperWrapper public publicKeeper;

  /// @inheritdoc IPublicKeeperJob
  IVaultRegistry public vaultRegistry;

  EnumerableSet.AddressSet internal _ignoredStrategies;
  /// @inheritdoc IPublicKeeperJob
  mapping(address => uint256) public lastWorkAt;
  /// @inheritdoc IPublicKeeperJob
  uint256 public workCooldown;

  constructor(
    address _governor,
    address _publicKeeper,
    address _mechanicsRegistry,
    address _vaultRegistry,
    uint256 _workCooldown
  ) Governable(_governor) MachineryReady(_mechanicsRegistry) {
    vaultRegistry = IVaultRegistry(_vaultRegistry);
    publicKeeper = IKeeperWrapper(_publicKeeper);
    if (_workCooldown > 0) _setWorkCooldown(_workCooldown);
  }

  // views

  /// @inheritdoc IPublicKeeperJob
  function isValidStrategy(address _strategy) external view returns (bool _isValid) {
    return _isValidStrategy(_strategy);
  }

  // setters

  /// @inheritdoc IPublicKeeperJob
  function setPublicKeeper(address _publicKeeper) external onlyGovernor {
    _setPublicKeeper(_publicKeeper);
  }

  /// @inheritdoc IPublicKeeperJob
  function setWorkCooldown(uint256 _workCooldown) external onlyGovernorOrMechanic {
    _setWorkCooldown(_workCooldown);
  }

  function ignoreStrategy(address _strategy) external onlyGovernorOrMechanic {
    _ignoreStrategy(_strategy);
  }

  function acknowledgeStrategy(address _strategy) external onlyGovernorOrMechanic {
    _acknowledgeStrategy(_strategy);
  }

  // internals

  function _isValidStrategy(address _strategy) internal view virtual returns (bool _isValid);

  function _setPublicKeeper(address _publicKeeper) internal {
    publicKeeper = IKeeperWrapper(_publicKeeper);
  }

  function _setWorkCooldown(uint256 _workCooldown) internal {
    if (_workCooldown == 0) revert ZeroCooldown();
    workCooldown = _workCooldown;
  }

  function _ignoreStrategy(address _strategy) internal {
    if (_ignoredStrategies.contains(_strategy)) revert StrategyAlreadyIgnored();
    emit StrategyIgnored(_strategy);
    _ignoredStrategies.add(_strategy);
  }

  function _acknowledgeStrategy(address _strategy) internal {
    if (!_ignoredStrategies.contains(_strategy)) revert StrategyNotIgnored();
    _ignoredStrategies.remove(_strategy);
    emit StrategyAcknowledged(_strategy);
  }

  function _workable(address _strategy) internal view virtual returns (bool) {
    if (!_isValidStrategy(_strategy)) revert InvalidStrategy();
    if (workCooldown == 0 || block.timestamp > lastWorkAt[_strategy] + workCooldown) return true;
    return false;
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