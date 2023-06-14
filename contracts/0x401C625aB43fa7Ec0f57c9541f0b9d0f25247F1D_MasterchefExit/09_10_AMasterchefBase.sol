// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { IERC20, SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { APermit } from './APermit.sol';

abstract contract AMasterchefBase is APermit, Ownable {
  using SafeERC20 for IERC20;

  event Add(uint256 indexed pid, uint256 allocPoint, address indexed token);
  event SetRewardDistributor(address indexed caller, address indexed rewardDistributor);
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event Claim(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event UpdateRewards(address indexed caller, uint256 amount, uint256 newRewardRate, uint256 newPeriodFinish);

  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }

  struct PoolInfo {
    address token;
    uint32 allocPoint;
    uint64 lastUpdateTime;
    uint256 totalStaked;
    uint256 accRewardPerShare;
    uint256 accUndistributedReward;
  }

  uint256 public constant PRECISION = 1e20;
  uint256 public immutable REWARDS_DURATION;
  address public immutable REWARD_TOKEN;

  uint256 public totalAllocPoint;
  uint256 public totalClaimedRewards;
  uint256 public rewardRate;
  uint256 public periodFinish;

  PoolInfo[] public poolInfo;
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  mapping(address => bool) private poolToken;

  constructor(address rewardToken_, uint256 rewardsDuration_) {
    REWARD_TOKEN = rewardToken_;
    REWARDS_DURATION = rewardsDuration_;
    periodFinish = block.timestamp + rewardsDuration_;
  }

  function add(uint32 allocPoint, address token) external onlyOwner {
    require(!poolToken[token], 'Masterchef: Token already added');
    require(token != REWARD_TOKEN, 'Masterchef: Staking reward token not supported');
    require(allocPoint != 0, 'Masterchef: Allocation must be non zero');

    if (totalAllocPoint != 0) _massUpdatePools();

    totalAllocPoint += allocPoint;

    poolInfo.push(
      PoolInfo({
        token: token,
        allocPoint: allocPoint,
        lastUpdateTime: uint64(block.timestamp),
        totalStaked: 0,
        accRewardPerShare: 0,
        accUndistributedReward: 0
      })
    );

    poolToken[address(token)] = true;

    emit Add(poolInfo.length - 1, allocPoint, token);
  }

  function deposit(uint256 pid, uint256 amount) public virtual {
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    _updatePool(pool);

    /// @dev Undistributed rewards to this pool are divided equally between all active pools.
    if (pool.totalStaked == 0) {
      _updateUndistributedRewards(pool.accUndistributedReward / PRECISION);
      pool.accUndistributedReward = 0;
    } else {
      _safeClaimRewards(pid, _getUserPendingReward(user.amount, user.rewardDebt, pool.accRewardPerShare));
    }

    _transferAmountIn(pool.token, amount);
    user.amount += amount;
    user.rewardDebt = (user.amount * pool.accRewardPerShare) / PRECISION;
    pool.totalStaked += amount;

    emit Deposit(msg.sender, pid, amount);
  }

  function depositWithPermit(uint256 pid, uint256 amount, PermitParameters memory _permitParams) external {
    _permitToken(_permitParams);
    deposit(pid, amount);
  }

  function withdraw(uint256 pid, uint256 amount) public {
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][msg.sender];
    _updatePool(pool);

    amount = Math.min(user.amount, amount);

    _safeClaimRewards(pid, _getUserPendingReward(user.amount, user.rewardDebt, pool.accRewardPerShare));

    user.amount -= amount;
    user.rewardDebt = (user.amount * pool.accRewardPerShare) / PRECISION;
    pool.totalStaked -= amount;
    _transferAmountOut(pool.token, amount);

    emit Withdraw(msg.sender, pid, amount);
  }

  /// @notice Caution this will clear any pending rewards without claiming them.
  function emergencyWithdraw(uint256 pid) external {
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][msg.sender];

    uint256 _amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;
    pool.totalStaked -= _amount;

    IERC20(pool.token).safeTransfer(address(msg.sender), _amount);
    emit EmergencyWithdraw(msg.sender, pid, _amount);
    // No mass update don't update pending rewards
  }

  /// @notice Adds rewards to the pool and updates the reward rate.
  /// Must add and evenly distribute rewards through the rewardsDuration.
  function updateRewards(uint256 amount) external virtual onlyOwner {
    require(totalAllocPoint != 0, 'Masterchef: Must initiate a pool before updating rewards');
    IERC20(REWARD_TOKEN).safeTransferFrom(msg.sender, address(this), amount);

    _updateUndistributedRewards(amount);
    emit UpdateRewards(msg.sender, amount, rewardRate, periodFinish);
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  function pendingReward(uint256 pid, address user_) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[pid];
    UserInfo storage user = userInfo[pid][user_];

    if (user.amount == 0) return 0;

    uint256 accRewardPerShare = pool.accRewardPerShare +
      _getPoolRewardsSinceLastUpdate(pool.lastUpdateTime, pool.allocPoint) /
      pool.totalStaked;

    return
      Math.min(
        IERC20(REWARD_TOKEN).balanceOf(address(this)),
        _getUserPendingReward(user.amount, user.rewardDebt, accRewardPerShare)
      );
  }

  function _updateUndistributedRewards(uint256 _amount) internal {
    // Updates pool to account for the previous rewardRate.
    _massUpdatePools();

    uint256 amount = _amount * PRECISION;
    if (block.timestamp < periodFinish) {
      uint256 undistributedRewards = rewardRate * (periodFinish - block.timestamp);
      amount += undistributedRewards;
    }
    rewardRate = amount / REWARDS_DURATION;
    periodFinish = block.timestamp + REWARDS_DURATION;
  }

  // Increases accRewardPerShare and accUndistributedReward since last update.
  // Every time there is an update on *stake amount* we should update THE pool.
  function _updatePool(PoolInfo storage pool) internal {
    uint256 poolRewards = _getPoolRewardsSinceLastUpdate(pool.lastUpdateTime, pool.allocPoint);

    if (poolRewards != 0) {
      if (pool.totalStaked == 0) {
        pool.accUndistributedReward += poolRewards;
      } else {
        pool.accRewardPerShare += poolRewards / pool.totalStaked;
      }
    }

    pool.lastUpdateTime = uint64(block.timestamp);
  }

  /// @notice Increases accRewardPerShare and accUndistributedReward for all pools since last update up to block.timestamp.
  /// Every time there is an update on *rewardRate* or *totalAllocPoint* we should update ALL pools.
  function _massUpdatePools() internal {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      _updatePool(poolInfo[pid]);
    }
  }

  function _safeClaimRewards(uint256 _pid, uint256 _amount) internal {
    if (_amount == 0) return;
    uint256 _claimable = Math.min(_amount, IERC20(REWARD_TOKEN).balanceOf(address(this)));
    totalClaimedRewards += _claimable;
    IERC20(REWARD_TOKEN).safeTransfer(msg.sender, _claimable);
    emit Claim(msg.sender, _pid, _claimable);
  }

  function _transferAmountIn(address _token, uint256 _amount) internal {
    if (_amount != 0) IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
  }

  function _transferAmountOut(address _token, uint256 _amount) internal {
    if (_amount != 0) IERC20(_token).safeTransfer(msg.sender, _amount);
  }

  // @notice Returns the total rewards allocated to a pool since last update.
  function _getPoolRewardsSinceLastUpdate(
    uint256 _poolLastUpdateTime,
    uint256 _poolAllocPoint
  ) internal view returns (uint256 _poolRewards) {
    // If _updatePool has not been called since periodFinish
    if (_poolLastUpdateTime > periodFinish) return 0;

    // If reward is not updated for longer than rewardsDuration periodFinish will be < than block.timestamp
    uint256 lastTimeRewardApplicable = Math.min(block.timestamp, periodFinish);

    return ((lastTimeRewardApplicable - _poolLastUpdateTime) * rewardRate * _poolAllocPoint) / totalAllocPoint;
  }

  function _getUserPendingReward(
    uint256 _userAmount,
    uint256 _userDebt,
    uint256 _poolAccRewardPerShare
  ) internal pure returns (uint256 _reward) {
    return (_userAmount * _poolAccRewardPerShare) / PRECISION - _userDebt;
  }
}