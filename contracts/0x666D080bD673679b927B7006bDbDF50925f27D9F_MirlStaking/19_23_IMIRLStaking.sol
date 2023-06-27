// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './libraries/SignedSafeMath.sol';
import './libraries/SafeMath.sol';
import './MIRLERC20.sol';
import './IMigratorChef.sol';

interface IMIRLStaking {
  /**
   * @dev Emitted when create a pool.
   */
  event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);

  /**
   * @dev Emitted when set allocPoint to a pool pid.
   */
  event LogSetPool(uint256 indexed pid, uint256 allocPoint);

  event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accumulatedMirlPerShare);

  /**
   * @dev Emitted when deposit to a pool pid.
   */
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

  /**
   * @dev Emitted when withdraw from pool pid.
   */
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

  /**
   * @dev Emitted when withdraw in emergency (no income).
   */
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

  /**
   * @dev Emitted when Harvest from pool pid.
   */
  event Harvest(address indexed user, uint256 indexed pid, uint256 amount);

  /// @notice Add a new LP to the pool. Can only be called by the owner.
  /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  /// @param allocPoint AP of the new pool.
  /// @param _lpToken Address of the LP ERC-20 token.
  function add(uint256 allocPoint, IERC20 _lpToken) external;

  /// @notice Update the given pool's MIRL allocation point. Can only be called by the owner.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _allocPoint New AP of the pool.
  function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;

  /// @notice Deposit LP tokens to MirlStaking for MIRL allocation.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount LP token amount to deposit.
  function deposit(uint256 pid, uint256 amount) external;

  /// @notice View function to see pending MIRL on frontend.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _user Address of user.
  /// @return pending MIRL reward for a given user.
  function pendingMirl(uint256 _pid, address _user) external view returns (uint256);

  /// @notice Withdraw LP tokens from MirlStaking.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount LP token amount to withdraw.
  function withdraw(uint256 pid, uint256 amount) external;

  /// @notice Harvest proceeds for transaction sender to `to`.
  /// @param pid The index of the pool. See `poolInfo`.
  function harvest(uint256 pid) external;

  /// @notice Withdraw LP tokens from MirlStaking and harvest proceeds for transaction sender to `to`.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount LP token amount to withdraw.
  function withdrawAndHarvest(uint256 pid, uint256 amount) external;

  /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
  /// @param pid The index of the pool. See `poolInfo`.
  function emergencyWithdraw(uint256 pid) external;

  //   function balanceOf(uint256 pid, address user) external view returns (uint256);
}