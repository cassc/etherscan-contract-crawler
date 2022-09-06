// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConcentratorConvexVault {
  /// @notice Emitted when someone change allowance.
  /// @param pid The pool id.
  /// @param owner The address of the owner.
  /// @param spender The address of the spender.
  /// @param value The new value of allowance.
  event Approval(uint256 indexed pid, address indexed owner, address indexed spender, uint256 value);

  /// @notice Emitted when someone deposits asset into this contract.
  /// @param pid The pool id.
  /// @param sender The address who sends underlying asset.
  /// @param recipient The address who will receive the pool shares.
  /// @param assetsIn The amount of asset deposited.
  /// @param sharesOut The amounf of pool shares received.
  event Deposit(
    uint256 indexed pid,
    address indexed sender,
    address indexed recipient,
    uint256 assetsIn,
    uint256 sharesOut
  );

  /// @notice Emitted when someone withdraws asset from this contract.
  /// @param pid The pool id.
  /// @param sender The address who call the function.
  /// @param owner The address who owns the assets.
  /// @param recipient The address who will receive the assets.
  /// @param assetsOut The amount of asset withdrawn.
  /// @param sharesIn The amounf of pool shares to withdraw.
  event Withdraw(
    uint256 indexed pid,
    address indexed sender,
    address indexed owner,
    address recipient,
    uint256 sharesIn,
    uint256 assetsOut
  );

  /// @notice Emitted when someone claim rewards from this contract.
  /// @param pid The pool id.
  /// @param sender The address who call the function.
  /// @param recipient The address who will receive the rewards;
  /// @param rewards The amount of reward received.
  event Claim(uint256 indexed pid, address indexed sender, address indexed recipient, uint256 rewards);

  /// @notice Emitted when someone harvests rewards.
  /// @param pid The pool id.
  /// @param caller The address who call the function.
  /// @param recipient The address of account to recieve the harvest bounty.
  /// @param rewards The total amount of rewards harvested.
  /// @param platformFee The amount of harvested assets as platform fee.
  /// @param harvestBounty The amount of harvested assets as harvest bounty.
  event Harvest(
    uint256 indexed pid,
    address indexed caller,
    address indexed recipient,
    uint256 rewards,
    uint256 platformFee,
    uint256 harvestBounty
  );

  /// @notice The address of reward token.
  function rewardToken() external view returns (address);

  /// @notice Return the amount of pending rewards for specific pool.
  /// @param pid The pool id.
  /// @param account The address of user.
  function pendingReward(uint256 pid, address account) external view returns (uint256);

  /// @notice Return the amount of pending AladdinCRV rewards for all pool.
  /// @param account The address of user.
  function pendingRewardAll(address account) external view returns (uint256);

  /// @notice Return the user share for specific user.
  /// @param pid The pool id to query.
  /// @param account The address of user.
  function getUserShare(uint256 pid, address account) external view returns (uint256);

  /// @notice Return the address of underlying token.
  /// @param pid The pool id to query.
  function underlying(uint256 pid) external view returns (address);

  /// @notice Return the total underlying token deposited.
  /// @param pid The pool id to query.
  function getTotalUnderlying(uint256 pid) external view returns (uint256);

  /// @notice Return the total pool share deposited.
  /// @param pid The pool id to query.
  function getTotalShare(uint256 pid) external view returns (uint256);

  /// @notice Returns the remaining number of shares that `spender` will be allowed to spend on behalf of `owner`.
  /// @param pid The pool id to query.
  /// @param owner The address of the owner.
  /// @param spender The address of the spender.
  function allowance(
    uint256 pid,
    address owner,
    address spender
  ) external view returns (uint256);

  /// @notice Sets `amount` as the allowance of `spender` over the caller's share.
  /// @param pid The pool id to query.
  /// @param spender The address of the spender.
  /// @param amount The amount of allowance.
  function approve(
    uint256 pid,
    address spender,
    uint256 amount
  ) external;

  /// @notice Deposit some token to specific pool for someone.
  /// @param pid The pool id.
  /// @param recipient The address of recipient who will recieve the token.
  /// @param assets The amount of token to deposit. -1 means deposit all.
  /// @return share The amount of share after deposit.
  function deposit(
    uint256 pid,
    address recipient,
    uint256 assets
  ) external returns (uint256 share);

  /// @notice Withdraw some token from specific pool and zap to token.
  /// @param pid The pool id.
  /// @param shares The share of token want to withdraw. -1 means withdraw all.
  /// @param recipient The address of account who will receive the assets.
  /// @param owner The address of user to withdraw from.
  /// @return assets The amount of token sent to recipient.
  function withdraw(
    uint256 pid,
    uint256 shares,
    address recipient,
    address owner
  ) external returns (uint256 assets);

  /// @notice claim pending rewards from specific pool.
  /// @param pid The pool id.
  /// @param recipient The address of account who will receive the rewards.
  /// @param minOut The minimum amount of pending reward to receive.
  /// @param claimAsToken The address of token to claim as. Use address(0) if claim as ETH
  /// @return claimed The amount of reward sent to the recipient.
  function claim(
    uint256 pid,
    address recipient,
    uint256 minOut,
    address claimAsToken
  ) external returns (uint256 claimed);

  /// @notice claim pending rewards from all pools.
  /// @param recipient The address of account who will receive the rewards.
  /// @param minOut The minimum amount of pending reward to receive.
  /// @param claimAsToken The address of token to claim as. Use address(0) if claim as ETH
  /// @return claimed The amount of reward sent to the recipient.
  function claimAll(
    uint256 minOut,
    address recipient,
    address claimAsToken
  ) external returns (uint256 claimed);

  /// @notice Harvest the pending reward and convert to aCRV.
  /// @param pid The pool id.
  /// @param recipient The address of account to receive harvest bounty.
  /// @param minOut The minimum amount of cvxCRV should get.
  /// @return harvested The amount of cvxCRV harvested after zapping all other tokens to it.
  function harvest(
    uint256 pid,
    address recipient,
    uint256 minOut
  ) external returns (uint256 harvested);
}