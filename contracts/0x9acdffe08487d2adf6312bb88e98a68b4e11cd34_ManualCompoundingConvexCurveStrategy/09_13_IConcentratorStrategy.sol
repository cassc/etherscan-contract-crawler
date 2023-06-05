// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConcentratorStrategy {
  /// @notice Return then name of the strategy.
  function name() external view returns (string memory);

  /// @notice Update the list of reward tokens.
  /// @param _rewards The address list of reward tokens to update.
  function updateRewards(address[] memory _rewards) external;

  /// @notice Deposit token to corresponding strategy.
  /// @dev Requirements:
  ///   + Caller should make sure the token is already transfered into the strategy contract.
  ///   + Caller should make sure the deposit amount is greater than zero.
  ///
  /// @param _recipient The address of recipient who will receive the share.
  /// @param _amount The amount of token to deposit.
  function deposit(address _recipient, uint256 _amount) external;

  /// @notice Withdraw underlying token or yield token from corresponding strategy.
  /// @dev Requirements:
  ///   + Caller should make sure the withdraw amount is greater than zero.
  ///
  /// @param _recipient The address of recipient who will receive the token.
  /// @param _amount The amount of token to withdraw.
  function withdraw(address _recipient, uint256 _amount) external;

  /// @notice Harvest possible rewards from strategy.
  ///
  /// @param _zapper The address of zap contract used to zap rewards.
  /// @param _intermediate The address of intermediate token to zap.
  /// @return amount The amount of corresponding reward token.
  function harvest(address _zapper, address _intermediate) external returns (uint256 amount);

  /// @notice Emergency function to execute arbitrary call.
  /// @dev This function should be only used in case of emergency. It should never be called explicitly
  ///  in any contract in normal case.
  ///
  /// @param _to The address of target contract to call.
  /// @param _value The value passed to the target contract.
  /// @param _data The calldata pseed to the target contract.
  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external payable returns (bool, bytes memory);

  /// @notice Do some extra work before migration.
  /// @param _newStrategy The address of new strategy.
  function prepareMigrate(address _newStrategy) external;

  /// @notice Do some extra work after migration.
  /// @param _newStrategy The address of new strategy.
  function finishMigrate(address _newStrategy) external;
}