// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IAladdinCRVConvexVault {
  enum ClaimOption {
    None,
    Claim,
    ClaimAsCvxCRV,
    ClaimAsCRV,
    ClaimAsCVX,
    ClaimAsETH
  }

  event Deposit(uint256 indexed _pid, address indexed _sender, uint256 _amount);
  event Withdraw(uint256 indexed _pid, address indexed _sender, uint256 _shares);
  event Claim(address indexed _sender, uint256 _reward, ClaimOption _option);
  event Harvest(address indexed _caller, uint256 _reward, uint256 _platformFee, uint256 _harvestBounty);

  event UpdateWithdrawalFeePercentage(uint256 indexed _pid, uint256 _feePercentage);
  event UpdatePlatformFeePercentage(uint256 indexed _pid, uint256 _feePercentage);
  event UpdateHarvestBountyPercentage(uint256 indexed _pid, uint256 _percentage);
  event UpdatePlatform(address indexed _platform);
  event UpdateZap(address indexed _zap);
  event UpdatePoolRewardTokens(uint256 indexed _pid, address[] _rewardTokens);
  event AddPool(uint256 indexed _pid, uint256 _convexPid, address[] _rewardTokens);
  event PausePoolDeposit(uint256 indexed _pid, bool _status);
  event PausePoolWithdraw(uint256 indexed _pid, bool _status);

  /// @notice Return the amount of pending AladdinCRV rewards for specific pool.
  /// @param _pid - The pool id.
  /// @param _account - The address of user.
  function pendingReward(uint256 _pid, address _account) external view returns (uint256);

  /// @notice Return the amount of pending AladdinCRV rewards for all pool.
  /// @param _account - The address of user.
  function pendingRewardAll(address _account) external view returns (uint256);

  /// @notice Return the user share for specific user.
  /// @param _pid The pool id to query.
  /// @param _account The address of user.
  function getUserShare(uint256 _pid, address _account) external view returns (uint256);

  /// @notice Return the total underlying token deposited.
  /// @param _pid The pool id to query.
  function getTotalUnderlying(uint256 _pid) external view returns (uint256);

  /// @notice Return the total pool share deposited.
  /// @param _pid The pool id to query.
  function getTotalShare(uint256 _pid) external view returns (uint256);

  /// @notice Deposit some token to specific pool.
  /// @dev This function is deprecated.
  /// @param _pid The pool id to query
  /// @param _amount The amount of token to deposit.
  /// @return share The amount of share after deposit.
  function deposit(uint256 _pid, uint256 _amount) external returns (uint256 share);

  /// @notice Deposit some token to specific pool for someone.
  /// @param _pid The pool id.
  /// @param _recipient The address of recipient who will recieve the token.
  /// @param _amount The amount of token to deposit.
  /// @return share The amount of share after deposit.
  function deposit(
    uint256 _pid,
    address _recipient,
    uint256 _amount
  ) external returns (uint256 share);

  /// @notice Deposit all token of the caller to specific pool.
  /// @dev This function is deprecated.
  /// @param _pid The pool id.
  /// @return share The amount of share after deposit.
  function depositAll(uint256 _pid) external returns (uint256 share);

  /// @notice Deposit all token of the caller to specific pool for someone.
  /// @param _pid The pool id.
  /// @param _recipient The address of recipient who will recieve the token.
  /// @return share The amount of share after deposit.
  function depositAll(uint256 _pid, address _recipient) external returns (uint256 share);

  /// @notice Deposit some token to specific pool with zap.
  /// @dev This function is deprecated.
  /// @param _pid The pool id.
  /// @param _token The address of token to deposit.
  /// @param _amount The amount of token to deposit.
  /// @param _minAmount The minimum amount of share to deposit.
  /// @return share The amount of share after deposit.
  function zapAndDeposit(
    uint256 _pid,
    address _token,
    uint256 _amount,
    uint256 _minAmount
  ) external payable returns (uint256 share);

  /// @notice Deposit some token to specific pool with zap for someone.
  /// @param _pid The pool id.
  /// @param _recipient The address of recipient who will recieve the token.
  /// @param _token The address of token to deposit.
  /// @param _amount The amount of token to deposit.
  /// @param _minAmount The minimum amount of share to deposit.
  /// @return share The amount of share after deposit.
  function zapAndDeposit(
    uint256 _pid,
    address _recipient,
    address _token,
    uint256 _amount,
    uint256 _minAmount
  ) external payable returns (uint256 share);

  /// @notice Deposit all token to specific pool with zap.
  /// @dev This function is deprecated.
  /// @param _pid The pool id.
  /// @param _token The address of token to deposit.
  /// @param _minAmount The minimum amount of share to deposit.
  /// @return share The amount of share after deposit.
  function zapAllAndDeposit(
    uint256 _pid,
    address _token,
    uint256 _minAmount
  ) external payable returns (uint256);

  /// @notice Deposit all token to specific pool with zap for someone.
  /// @param _pid The pool id.
  /// @param _recipient The address of recipient who will recieve the token.
  /// @param _token The address of token to deposit.
  /// @param _minAmount The minimum amount of share to deposit.
  /// @return share The amount of share after deposit.
  function zapAllAndDeposit(
    uint256 _pid,
    address _recipient,
    address _token,
    uint256 _minAmount
  ) external payable returns (uint256);

  /// @notice Withdraw some token from specific pool and zap to token.
  /// @param _pid - The pool id.
  /// @param _shares - The share of token want to withdraw.
  /// @param _token - The address of token zapping to.
  /// @param _minOut - The minimum amount of token to receive.
  /// @return withdrawn - The amount of token sent to caller.
  function withdrawAndZap(
    uint256 _pid,
    uint256 _shares,
    address _token,
    uint256 _minOut
  ) external returns (uint256);

  /// @notice Withdraw all token from specific pool and zap to token.
  /// @param _pid - The pool id.
  /// @param _token - The address of token zapping to.
  /// @param _minOut - The minimum amount of token to receive.
  /// @return withdrawn - The amount of token sent to caller.
  function withdrawAllAndZap(
    uint256 _pid,
    address _token,
    uint256 _minOut
  ) external returns (uint256);

  /// @notice Withdraw some token from specific pool and claim pending rewards.
  /// @param _pid - The pool id.
  /// @param _shares - The share of token want to withdraw.
  /// @param _minOut - The minimum amount of pending reward to receive.
  /// @param _option - The claim option (don't claim, as aCRV, cvxCRV, CRV, CVX, or ETH)
  /// @return withdrawn - The amount of token sent to caller.
  /// @return claimed - The amount of reward sent to caller.
  function withdrawAndClaim(
    uint256 _pid,
    uint256 _shares,
    uint256 _minOut,
    ClaimOption _option
  ) external returns (uint256, uint256);

  /// @notice Withdraw all share of token from specific pool and claim pending rewards.
  /// @param _pid - The pool id.
  /// @param _minOut - The minimum amount of pending reward to receive.
  /// @param _option - The claim option (as aCRV, cvxCRV, CRV, CVX, or ETH)
  /// @return withdrawn - The amount of token sent to caller.
  /// @return claimed - The amount of reward sent to caller.
  function withdrawAllAndClaim(
    uint256 _pid,
    uint256 _minOut,
    ClaimOption _option
  ) external returns (uint256, uint256);

  /// @notice claim pending rewards from specific pool.
  /// @param _pid - The pool id.
  /// @param _minOut - The minimum amount of pending reward to receive.
  /// @param _option - The claim option (as aCRV, cvxCRV, CRV, CVX, or ETH)
  /// @return claimed - The amount of reward sent to caller.
  function claim(
    uint256 _pid,
    uint256 _minOut,
    ClaimOption _option
  ) external returns (uint256);

  /// @notice claim pending rewards from all pools.
  /// @param _minOut - The minimum amount of pending reward to receive.
  /// @param _option - The claim option (as aCRV, cvxCRV, CRV, CVX, or ETH)
  /// @return claimed - The amount of reward sent to caller.
  function claimAll(uint256 _minOut, ClaimOption _option) external returns (uint256);

  /// @notice Harvest the pending reward and convert to aCRV.
  /// @param _pid - The pool id.
  /// @param _recipient - The address of account to receive harvest bounty.
  /// @param _minimumOut - The minimum amount of cvxCRV should get.
  /// @return harvested - The amount of cvxCRV harvested after zapping all other tokens to it.
  function harvest(
    uint256 _pid,
    address _recipient,
    uint256 _minimumOut
  ) external returns (uint256);
}