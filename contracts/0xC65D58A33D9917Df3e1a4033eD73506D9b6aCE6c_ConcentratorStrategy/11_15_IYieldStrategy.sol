// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IYieldStrategy {
  /// @notice Return the the address of the yield token.
  function yieldToken() external view returns (address);

  /// @notice Return the the address of the underlying token.
  /// @dev The underlying token maybe the same as the yield token.
  function underlyingToken() external view returns (address);

  /// @notice Return the number of underlying token for each yield token worth, multiplied by 1e18.
  function underlyingPrice() external view returns (uint256);

  /// @notice Return the total number of underlying token in the contract.
  function totalUnderlyingToken() external view returns (uint256);

  /// @notice Return the total number of yield token in the contract.
  function totalYieldToken() external view returns (uint256);

  /// @notice Deposit underlying token or yield token to corresponding strategy.
  /// @dev Requirements:
  ///   + Caller should make sure the token is already transfered into the strategy contract.
  ///   + Caller should make sure the deposit amount is greater than zero.
  ///
  /// @param _recipient The address of recipient who will receive the share.
  /// @param _amount The amount of token to deposit.
  /// @param _isUnderlying Whether the deposited token is underlying token.
  ///
  /// @return _yieldAmount The amount of yield token deposited.
  function deposit(
    address _recipient,
    uint256 _amount,
    bool _isUnderlying
  ) external returns (uint256 _yieldAmount);

  /// @notice Withdraw underlying token or yield token from corresponding strategy.
  /// @dev Requirements:
  ///   + Caller should make sure the withdraw amount is greater than zero.
  ///
  /// @param _recipient The address of recipient who will receive the token.
  /// @param _amount The amount of yield token to withdraw.
  /// @param _asUnderlying Whether the withdraw as underlying token.
  ///
  /// @return _returnAmount The amount of token sent to `_recipient`.
  function withdraw(
    address _recipient,
    uint256 _amount,
    bool _asUnderlying
  ) external returns (uint256 _returnAmount);

  /// @notice Harvest possible rewards from strategy.
  /// @dev Part of the reward tokens will be sold to underlying token.
  ///
  /// @return _underlyingAmount The amount of underlying token harvested.
  /// @return _rewardTokens The address list of extra reward tokens.
  /// @return _amounts The list of amount of corresponding extra reward token.
  function harvest()
    external
    returns (
      uint256 _underlyingAmount,
      address[] memory _rewardTokens,
      uint256[] memory _amounts
    );

  /// @notice Migrate all yield token in current strategy to another strategy.
  /// @param _strategy The address of new yield strategy.
  function migrate(address _strategy) external returns (uint256 _yieldAmount);

  /// @notice Notify the target strategy that the migration is finished.
  /// @param _yieldAmount The amount of yield token migrated.
  function onMigrateFinished(uint256 _yieldAmount) external;

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
}