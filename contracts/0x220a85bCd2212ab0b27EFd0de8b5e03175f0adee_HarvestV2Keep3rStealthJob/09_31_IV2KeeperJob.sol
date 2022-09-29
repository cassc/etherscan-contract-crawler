// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;
import './external/IV2Keeper.sol';

interface IV2KeeperJob {
  // errors

  /// @notice Throws if the strategy being added has already been added
  error StrategyAlreadyAdded();
  /// @notice Throws if the strategy being summoned is not added
  error StrategyNotAdded();
  /// @notice Throws if a keeper tries to work a non-workable strategy
  error StrategyNotWorkable();
  /// @notice Throws if the cooldown is being set to 0
  error ZeroCooldown();

  // events

  /// @notice Emitted when a new strategy is added
  /// @param _strategy Address of the strategy being added
  /// @param _requiredAmount Estimated amount of gas required to trigger the strategy
  event StrategyAdded(address _strategy, uint256 _requiredAmount);

  /// @notice Emitted when a strategy is modified
  /// @param _strategy Address of the strategy being modified
  /// @param _requiredAmount New estimated amount of gas required to trigger the strategy
  event StrategyModified(address _strategy, uint256 _requiredAmount);

  /// @notice Emitted when a strategy is removed
  /// @param _strategy Address of the strategy being removed
  event StrategyRemoved(address _strategy);

  /// @notice Emitted when a strategy is worked
  /// @param _strategy Address of the strategy being worked
  event KeeperWorked(address _strategy);

  /// @notice Emitted when a strategy is force-worked by governor or mechanic
  /// @param _strategy Address of the strategy being force-worked
  event ForceWorked(address _strategy);

  // views

  /// @return _v2Keeper Address of v2Keeper
  function v2Keeper() external view returns (IV2Keeper _v2Keeper);

  /// @return _strategies List of added strategies
  function strategies() external view returns (address[] memory _strategies);

  /// @return _workCooldown Amount of seconds to wait until a strategy can be worked again
  function workCooldown() external view returns (uint256 _workCooldown);

  /// @param _strategy Address of the strategy to query
  /// @return _isWorkable Whether the queried strategy is workable or not
  function workable(address _strategy) external view returns (bool _isWorkable);

  /// @param _strategy Address of the strategy to query
  /// @return _lastWorkAt Timestamp of the last time the strategy was worked
  function lastWorkAt(address _strategy) external view returns (uint256 _lastWorkAt);

  /// @param _strategy Address of the strategy to query
  /// @return _requiredAmount Estimated amount of gas that the strategy requires to be executed
  function requiredAmount(address _strategy) external view returns (uint256 _requiredAmount);

  // methods

  /// @param _v2Keeper Address of the new v2Keeper to set
  function setV2Keeper(address _v2Keeper) external;

  /// @param _workCooldown Amount of seconds to wait until a strategy can be worked again
  function setWorkCooldown(uint256 _workCooldown) external;

  /// @param _strategy Address of the strategy to add
  /// @param _requiredAmount Amount of gas that the strategy requires to execute
  function addStrategy(address _strategy, uint256 _requiredAmount) external;

  /// @param _strategies Array of addresses of strategies to add
  /// @param _requiredAmount Array of amount of gas that each strategy requires to execute
  function addStrategies(address[] calldata _strategies, uint256[] calldata _requiredAmount) external;

  /// @param _strategy Address of the strategy to modify
  /// @param _requiredAmount New amount of gas that te strategy requires to execute
  function updateRequiredAmount(address _strategy, uint256 _requiredAmount) external;

  /// @param _strategies Array of addresses of strategies to modify
  /// @param _requiredAmounts Array of new amounts of gas that each strategy requires to execute
  function updateRequiredAmounts(address[] calldata _strategies, uint256[] calldata _requiredAmounts) external;

  /// @param _strategy Address of the strategy to remove
  function removeStrategy(address _strategy) external;

  /// @notice Function to be called by the keeper that triggers the execution of the given strategy
  /// @param _strategy Address of the strategy to be worked
  function work(address _strategy) external;

  /// @notice Function to be called by governor or mechanics that triggers the execution of the given strategy
  /// @notice This function bypasses the workable checks
  /// @param _strategy Address of the strategy to be worked
  function forceWork(address _strategy) external;
}