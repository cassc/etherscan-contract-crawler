// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;
import './external/IKeeperWrapper.sol';
import './external/IVaultRegistry.sol';

interface IPublicKeeperJob {
  // errors

  /// @notice Throws if the strategy being worked is not valid
  error InvalidStrategy();
  /// @notice Throws if the strategy being added has already been added
  error StrategyAlreadyIgnored();
  /// @notice Throws if the strategy being summoned is not added
  error StrategyNotIgnored();
  /// @notice Throws if a keeper tries to work a non-workable strategy
  error StrategyNotWorkable();
  /// @notice Throws if the cooldown is being set to 0
  error ZeroCooldown();

  // events

  /// @notice Emitted when a strategy is worked
  /// @param _strategy Address of the strategy being worked
  event KeeperWorked(address _strategy);

  /// @notice Emitted when a strategy is force-worked by governor or mechanic
  /// @param _strategy Address of the strategy being force-worked
  event ForceWorked(address _strategy);

  /// @notice Emitted when a new strategy is added to the ignore list
  /// @param _strategy Address of the strategy being added to the ignore list
  event StrategyIgnored(address _strategy);

  /// @notice Emitted when a strategy is removed from the ignore list
  /// @param _strategy Address of the strategy being removed from the ignore list
  event StrategyAcknowledged(address _strategy);

  // views

  function isValidStrategy(address _strategy) external view returns (bool _isValid);

  /// @return _publicKeeper Address of the public Keeper wrapper
  function publicKeeper() external view returns (IKeeperWrapper _publicKeeper);

  /// @return _vaultRegistry Address of the vault registry
  function vaultRegistry() external view returns (IVaultRegistry _vaultRegistry);

  /// @return _workCooldown Amount of seconds to wait until a strategy can be worked again
  function workCooldown() external view returns (uint256 _workCooldown);

  /// @param _strategy Address of the strategy to query
  /// @return _isWorkable Whether the queried strategy is workable or not
  function workable(address _strategy) external view returns (bool _isWorkable);

  /// @param _strategy Address of the strategy to query
  /// @return _lastWorkAt Timestamp of the last time the strategy was worked
  function lastWorkAt(address _strategy) external view returns (uint256 _lastWorkAt);

  // methods

  /// @param _publicKeeper Address of the new v2Keeper to set
  function setPublicKeeper(address _publicKeeper) external;

  /// @param _workCooldown Amount of seconds to wait until a strategy can be worked again
  function setWorkCooldown(uint256 _workCooldown) external;

  /// @param _strategy Address of the strategy to add
  function ignoreStrategy(address _strategy) external;

  /// @param _strategy Address of the strategy to remove
  function acknowledgeStrategy(address _strategy) external;

  /// @notice Function to be called by the keeper that triggers the execution of the given strategy
  /// @param _strategy Address of the strategy to be worked
  function work(address _strategy) external;

  /// @notice Function to be called by governor or mechanics that triggers the execution of the given strategy
  /// @notice This function bypasses the workable checks
  /// @param _strategy Address of the strategy to be worked
  function forceWork(address _strategy) external;
}