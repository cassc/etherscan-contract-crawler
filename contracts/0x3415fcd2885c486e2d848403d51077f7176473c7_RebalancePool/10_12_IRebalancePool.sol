// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IRebalancePool {
  /**********
   * Events *
   **********/

  /// @notice Emitted when user deposit asset into this contract.
  /// @param owner The address of asset owner.
  /// @param reciever The address of recipient of the asset in this contract.
  /// @param amount The amount of asset deposited.
  event Deposit(address indexed owner, address indexed reciever, uint256 amount);

  /// @notice Emitted when the amount of deposited asset changed due to liquidation or deposit or unlock.
  /// @param owner The address of asset owner.
  /// @param newDeposit The new amount of deposited asset.
  /// @param loss The amount of asset used by liquidation.
  event UserDepositChange(address indexed owner, uint256 newDeposit, uint256 loss);

  /// @notice Emitted when the amount of unlocking asset changed due to liquidation or unlock or withdraw.
  /// @param owner The address of asset owner.
  /// @param newUnlock The new amount of unlocking asset.
  /// @param loss The amount of asset used by liquidation.
  event UserUnlockChange(address indexed owner, uint256 newUnlock, uint256 loss);

  /// @notice Emitted when user unlock part of its deposition.
  /// @param amount The amount of token to unlock.
  /// @param unlockAt The timestamp in second when the asset will be unlocked.
  event Unlock(address indexed owner, uint256 amount, uint256 unlockAt);

  /// @notice Emitted when user withdraw unlocked asset.
  /// @param owner The address of asset owner.
  /// @param amount The amount of token to withdraw.
  event WithdrawUnlocked(address indexed owner, uint256 amount);

  /// @notice Emitted when new rewards are deposited to this contract.
  /// @param token The address of the token.
  /// @param amount The amount of token deposited.
  event DepositReward(address indexed token, uint256 amount);

  /// @notice Emitted when user claim pending reward token.
  /// @param owner The address of asset owner.
  /// @param token The address of token.
  /// @param amount The amount of pending reward claimed.
  event Claim(address indexed owner, address indexed token, uint256 amount);

  /// @notice Emitted when liquidation happens.
  /// @param liquidated The amount of asset liquidated.
  /// @param baseGained The amount of base token gained.
  event Liquidate(uint256 liquidated, uint256 baseGained);

  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the address of underlying token of this contract.
  function asset() external view returns (address);

  /// @notice Return the total amount of asset deposited to this contract.
  function totalSupply() external view returns (uint256);

  /// @notice Return the amount of deposited asset for some specific user.
  /// @param account The address of user to query.
  function balanceOf(address account) external view returns (uint256);

  /// @notice Return the amount of unlocked asset for some specific user.
  /// @param account The address of user to query.
  function unlockedBalanceOf(address account) external view returns (uint256);

  /// @notice Return the amount of unlocking asset for some specific user.
  /// @param account The address of user to query.
  /// @return balance The amount of unlocking asset.
  /// @return unlockAt The timestamp in second when the asset is unlocked.
  function unlockingBalanceOf(address account) external view returns (uint256 balance, uint256 unlockAt);

  /// @notice Return the amount of reward token can be claimed.
  /// @param account The address of user to query.
  /// @param token The address of reward token to query.
  function claimable(address account, address token) external view returns (uint256);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Deposit some asset to this contract.
  /// @dev Use `amount=uint256(-1)` if you want to deposit all asset held.
  /// @param amount The amount of asset to deposit.
  /// @param recipient The address of receiver for the deposited asset.
  function deposit(uint256 amount, address recipient) external;

  /// @notice Unlock some deposited asset.
  /// @dev If the amount if larger than current deposited asset, all asset will be used.
  /// @param amount The amount of asset to unlock.
  function unlock(uint256 amount) external;

  /// @notice Withdraw unlocked asset from this contract.
  /// @param _claim Whether the user want to claim pending rewards.
  /// @param unwrap Whether the user want to unwrap autocompounding rewards.
  function withdrawUnlocked(bool _claim, bool unwrap) external;

  /// @notice Claim pending reward from this contract.
  /// @param token The address of token to claim.
  /// @param unwrap Whether the user want to unwrap autocompounding rewards.
  function claim(address token, bool unwrap) external;

  /// @notice Claim multiple pending rewards from this contract.
  /// @param tokens The list of reward tokens to claim.
  /// @param unwrap Whether the user want to unwrap autocompounding rewards.
  function claim(address[] memory tokens, bool unwrap) external;

  /// @notice Liquidate asset for base token.
  /// @param maxAmount The maximum amount of asset to liquidate.
  /// @param minBaseOut The minimum amount of base token should receive.
  /// @return liquidated The amount of asset liquidated.
  /// @return baseOut The amount of base token received.
  function liquidate(uint256 maxAmount, uint256 minBaseOut) external returns (uint256 liquidated, uint256 baseOut);

  /// @notice Update the snapshot for some specific user.
  /// @param account The address of user to update.
  function updateAccountSnapshot(address account) external;

  /// @notice Deposit some reward token to this contract.
  /// @param token The address of token to deposit.
  /// @param amount The amount of token to deposit.
  function depositReward(address token, uint256 amount) external;
}