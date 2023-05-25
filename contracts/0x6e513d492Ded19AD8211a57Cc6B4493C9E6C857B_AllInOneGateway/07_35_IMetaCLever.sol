// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IMetaCLever {
  event Deposit(uint256 indexed _strategyIndex, address indexed _account, uint256 _share, uint256 _amount);
  event Withdraw(uint256 indexed _strategyIndex, address indexed _account, uint256 _share, uint256 _amount);
  event Repay(address indexed _account, address indexed _underlyingToken, uint256 _amount);
  event Mint(address indexed _account, address indexed _recipient, uint256 _amount);
  event Burn(address indexed _account, address indexed _recipient, uint256 _amount);
  event Claim(uint256 indexed _strategyIndex, address indexed _rewardToken, uint256 _rewardAmount);
  event Harvest(uint256 indexed _strategyIndex, uint256 _reward, uint256 _platformFee, uint256 _harvestBounty);

  /// @notice Deposit underlying token or yield token as credit to this contract.
  ///
  /// @param _strategyIndex The yield strategy to deposit.
  /// @param _recipient The address of recipient who will receive the credit.
  /// @param _amount The number of token to deposit.
  /// @param _minShareOut The minimum share of yield token should be received.
  /// @param _isUnderlying Whether it is underlying token or yield token.
  ///
  /// @return _shares Return the amount of yield token shares received.
  function deposit(
    uint256 _strategyIndex,
    address _recipient,
    uint256 _amount,
    uint256 _minShareOut,
    bool _isUnderlying
  ) external returns (uint256 _shares);

  /// @notice Withdraw underlying token or yield token from this contract.
  ///
  /// @param _strategyIndex The yield strategy to withdraw.
  /// @param _recipient The address of recipient who will receive the token.
  /// @param _share The number of yield token share to withdraw.
  /// @param _minAmountOut The minimum amount of token should be receive.
  /// @param _asUnderlying Whether to receive underlying token or yield token.
  ///
  /// @return The amount of token sent to `_recipient`.
  function withdraw(
    uint256 _strategyIndex,
    address _recipient,
    uint256 _share,
    uint256 _minAmountOut,
    bool _asUnderlying
  ) external returns (uint256);

  /// @notice Repay debt with underlying token.
  ///
  /// @dev If the repay exceed current debt amount, a refund will be executed and only
  /// sufficient amount for debt plus fee will be taken.
  ///
  /// @param _underlyingToken The address of underlying token.
  /// @param _recipient The address of the recipient who will receive credit.
  /// @param _amount The amount of underlying token to repay.
  function repay(
    address _underlyingToken,
    address _recipient,
    uint256 _amount
  ) external;

  /// @notice Mint certern amount of debt tokens from caller's account.
  ///
  /// @param _recipient The address of the recipient who will receive the debt tokens.
  /// @param _amount The amount of debt token to mint.
  /// @param _depositToFurnace Whether to deposit the debt tokens to Furnace contract.
  function mint(
    address _recipient,
    uint256 _amount,
    bool _depositToFurnace
  ) external;

  /// @notice Burn certern amount of debt tokens from caller's balance to pay debt for someone.
  ///
  /// @dev If the repay exceed current debt amount, a refund will be executed and only
  /// sufficient amount for debt plus fee will be burned.
  ///
  /// @param _recipient The address of the recipient.
  /// @param _amount The amount of debt token to burn.
  function burn(address _recipient, uint256 _amount) external;

  /// @notice Claim extra rewards from strategy.
  ///
  /// @param _strategyIndex The yield strategy to claim.
  /// @param _recipient The address of recipient who will receive the rewards.
  function claim(uint256 _strategyIndex, address _recipient) external;

  /// @notice Claim extra rewards from all deposited strategies.
  ///
  /// @param _recipient The address of recipient who will receive the rewards.
  function claimAll(address _recipient) external;

  /// @notice Harvest rewards from corresponding yield strategy.
  ///
  /// @param _strategyIndex The yield strategy to harvest.
  /// @param _recipient The address of recipient who will receive the harvest bounty.
  /// @param _minimumOut The miminim amount of rewards harvested.
  ///
  /// @return The actual amount of reward tokens harvested.
  function harvest(
    uint256 _strategyIndex,
    address _recipient,
    uint256 _minimumOut
  ) external returns (uint256);
}