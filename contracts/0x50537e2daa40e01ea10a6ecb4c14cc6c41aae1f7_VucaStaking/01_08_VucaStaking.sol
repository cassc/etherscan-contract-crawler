// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { VucaOwnable } from "./VucaOwnable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// VUCA + Pellar + LightLink 2023

contract VucaStaking is VucaOwnable {
  using SafeERC20 for IERC20;

  // constants
  enum UpdateParam {
    MaxStakeTokens,
    RewardTokensPerBlock,
    EndBlock
  }

  // Staking user data
  struct Staking {
    uint256 amount;
    uint256 accumulatedRewards;
    uint256 minusRewards; // rewards that user can not get computed by block
  }

  struct Extension {
    uint256 currentPoolChangeId;
    uint256 totalUserRewards;
    uint256 rewardsWithdrew;
    uint256 totalPoolRewards;
    uint256 noAddressRewards;
  }

  // Staking pool
  struct Pool {
    bool inited;
    address rewardToken; // require init
    address stakeToken; // require init
    uint32 updateDelay; // blocks // default 2048 blocks = 8 hours
    uint256 maxStakeTokens; // require init
    uint256 startBlock; // require init
    uint256 endBlock; // require init
    uint256 rewardTokensPerBlock; // require init
    uint256 tokensStaked;
    uint256 lastRewardedBlock; // require init
    uint256 accumulatedRewardsPerShare;
    Extension extension;
  }

  struct PoolChanges {
    bool applied;
    UpdateParam updateParamId;
    uint256 updateParamValue;
    uint256 timestamp;
    uint256 blockNumber;
  }

  uint256 public constant REWARDS_PRECISION = 1e18; // adjustment

  uint16 public currentPoolId;

  mapping(uint16 => Pool) public pools; // staking events

  // Mapping poolId =>
  mapping(uint16 => PoolChanges[]) public poolsChanges; // staking changes queue

  // Mapping poolId => user address => Staking
  mapping(uint16 => mapping(address => Staking)) public stakingUsersInfo;

  // Events
  event StakingChanged(uint8 indexed eventId, address indexed user, uint16 indexed poolId, Pool pool, Staking staking);
  event PoolCreated(uint8 indexed eventId, uint16 indexed poolId, Pool pool, uint256 activeBlock);
  event PoolUpdated(uint8 indexed eventId, uint16 indexed poolId, Pool pool, PoolChanges changes, uint256 activeBlock);
  event RewardsRetrieved(uint8 indexed eventId, uint16 indexed poolId, address sender, address to, uint256 amount);

  // Constructor
  constructor() {}

  /* View */
  // rewards w/o adjustment
  function getRawRewards(uint16 _poolId, address _account) internal view returns (uint256) {
    Staking memory staking = stakingUsersInfo[_poolId][_account];
    Pool memory pool = pools[_poolId];

    pool = _getPoolRewards(pool, block.number);

    return staking.accumulatedRewards + (staking.amount * pool.accumulatedRewardsPerShare) - staking.minusRewards;
  }

  // rewards with adjustment
  function getRewards(uint16 _poolId, address _account) internal view returns (uint256) {
    uint256 rawRewards = getRawRewards(_poolId, _account);

    return rawRewards / (10**IERC20Helper(pools[_poolId].stakeToken).decimals()) / REWARDS_PRECISION;
  }

  /* User */
  function stake(uint16 _poolId, uint256 _amount) external {
    _updatePoolInfo(_poolId);
    Pool storage pool = pools[_poolId];
    require(pool.startBlock <= block.number, "Staking inactive");
    require(pool.endBlock >= block.number, "Staking ended");
    require(_amount > 0, "Invalid amount");
    require(_amount + pool.tokensStaked <= pool.maxStakeTokens, "Exceed max stake tokens");

    Staking storage staking = stakingUsersInfo[_poolId][msg.sender];

    _updatePoolRewards(_poolId, block.number);
    // Update user
    staking.accumulatedRewards = getRawRewards(_poolId, msg.sender);
    staking.amount += _amount;
    staking.minusRewards = staking.amount * pool.accumulatedRewardsPerShare;

    // Update pool
    pool.tokensStaked += _amount;

    // Deposit tokens
    emit StakingChanged(0, msg.sender, _poolId, pool, staking);
    IERC20(pool.stakeToken).safeTransferFrom(address(msg.sender), address(this), _amount);
  }

  // rewards will be forfeited if this is called (use unStake to obtain rewards after staking period)
  function emergencyWithdraw(uint16 _poolId) external {
    _updatePoolInfo(_poolId);
    Pool storage pool = pools[_poolId];
    Staking storage staking = stakingUsersInfo[_poolId][msg.sender];
    uint256 amount = staking.amount;
    require(staking.amount > 0, "Insufficient funds");

    _updatePoolRewards(_poolId, block.number);
    uint256 rewards = getRewards(_poolId, msg.sender);
    // Update pool
    pool.tokensStaked -= amount;
    pool.extension.noAddressRewards += rewards;

    // Update staker
    staking.accumulatedRewards = 0;
    staking.minusRewards = 0;
    staking.amount = 0;

    emit StakingChanged(0, msg.sender, _poolId, pool, staking);

    // Withdraw tokens
    IERC20(pool.stakeToken).safeTransfer(address(msg.sender), amount);
  }

  // unstake, get rewards
  function unStake(uint16 _poolId) external {
    _updatePoolInfo(_poolId);
    Pool storage pool = pools[_poolId];
    require(pool.endBlock < block.number, "Staking active");

    Staking storage staking = stakingUsersInfo[_poolId][msg.sender];
    uint256 amount = staking.amount;
    require(staking.amount > 0, "Insufficient funds");

    _updatePoolRewards(_poolId, block.number);
    uint256 rewards = getRewards(_poolId, msg.sender);

    // Update pool
    pool.tokensStaked -= amount;

    // Update staker
    staking.accumulatedRewards = 0;
    staking.minusRewards = 0;
    staking.amount = 0;

    emit StakingChanged(0, msg.sender, _poolId, pool, staking);

    // Pay rewards
    IERC20(pool.rewardToken).safeTransfer(msg.sender, rewards);

    // Withdraw tokens
    IERC20(pool.stakeToken).safeTransfer(address(msg.sender), amount);
  }

  /* Admin */
  function createPool(
    address _rewardToken,
    address _stakeToken,
    uint256 _maxStakeTokens,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _rewardTokensPerBlock,
    uint32 _updateDelay
  ) external onlyOwner {
    require(_startBlock > block.number && _startBlock < _endBlock, "Invalid start/end block");
    require(_rewardToken != address(0), "Invalid reward token");
    require(_stakeToken != address(0), "Invalid staking token");
    require(currentPoolId == 0, "Staking pool was already created");

    pools[currentPoolId].inited = true;
    pools[currentPoolId].rewardToken = _rewardToken;
    pools[currentPoolId].stakeToken = _stakeToken;

    pools[currentPoolId].maxStakeTokens = _maxStakeTokens;
    pools[currentPoolId].startBlock = _startBlock;
    pools[currentPoolId].endBlock = _endBlock;

    pools[currentPoolId].rewardTokensPerBlock = _rewardTokensPerBlock * (10**IERC20Helper(_stakeToken).decimals()) * REWARDS_PRECISION;
    pools[currentPoolId].lastRewardedBlock = _startBlock;
    pools[currentPoolId].updateDelay = _updateDelay; // = 8 hours;

    emit PoolCreated(1, currentPoolId, pools[currentPoolId], block.number);
    currentPoolId += 1;
  }

  function depositPoolReward(uint16 _poolId, uint256 _amount) public {
    Pool storage pool = pools[_poolId];
    require(pool.inited, "Pool invalid");
    require(_amount > 0, "Invalid amount");
    _updatePoolInfo(_poolId);

    pool.extension.totalPoolRewards += _amount;

    IERC20(pool.rewardToken).safeTransferFrom(msg.sender, address(this), _amount);

    PoolChanges memory changes;
    emit PoolUpdated(2, _poolId, pools[_poolId], changes, block.number);
  }

  function updateMaxStakeTokens(uint16 _poolId, uint256 _maxStakeTokens) external onlyOwner {
    require(pools[_poolId].inited, "Invalid Pool");
    _updatePoolInfo(_poolId);

    require(block.number + pools[_poolId].updateDelay < pools[_poolId].endBlock, "Exceed Blocks");
    require(pools[_poolId].extension.currentPoolChangeId + 10 > poolsChanges[_poolId].length, "Exceed pending changes");

    PoolChanges memory changes = PoolChanges({
      applied: false, //
      updateParamId: UpdateParam.MaxStakeTokens,
      updateParamValue: _maxStakeTokens,
      timestamp: block.timestamp,
      blockNumber: block.number
    });
    poolsChanges[_poolId].push(changes);

    emit PoolUpdated(2, _poolId, pools[_poolId], changes, block.number + pools[_poolId].updateDelay);
  }

  function updateRewardTokensPerBlock(uint16 _poolId, uint256 _rewardTokensPerBlock) external onlyOwner {
    require(pools[_poolId].inited, "Invalid Pool");
    _updatePoolInfo(_poolId);

    require(block.number + pools[_poolId].updateDelay < pools[_poolId].endBlock, "Exceed Blocks");
    require(pools[_poolId].extension.currentPoolChangeId + 10 > poolsChanges[_poolId].length, "Exceed pending changes");

    uint256 rewardTokensPerBlock = _rewardTokensPerBlock * (10**IERC20Helper(pools[_poolId].stakeToken).decimals()) * REWARDS_PRECISION;

    PoolChanges memory changes = PoolChanges({
      applied: false, //
      updateParamId: UpdateParam.RewardTokensPerBlock,
      updateParamValue: rewardTokensPerBlock,
      timestamp: block.timestamp,
      blockNumber: block.number
    });
    poolsChanges[_poolId].push(changes);

    emit PoolUpdated(2, _poolId, pools[_poolId], changes, block.number + pools[_poolId].updateDelay);
  }

  // end block updatable
  function updateEndBlock(uint16 _poolId, uint256 _endBlock) external onlyOwner {
    require(pools[_poolId].inited, "Invalid Pool");
    _updatePoolInfo(_poolId);

    require(_endBlock > block.number + pools[_poolId].updateDelay, "Invalid input");
    require(block.number + pools[_poolId].updateDelay < pools[_poolId].endBlock, "Exceed Blocks");
    require(pools[_poolId].extension.currentPoolChangeId + 10 > poolsChanges[_poolId].length, "Exceed pending changes");

    PoolChanges memory changes = PoolChanges({
      applied: false, //
      updateParamId: UpdateParam.EndBlock,
      updateParamValue: _endBlock,
      timestamp: block.timestamp,
      blockNumber: block.number
    });
    poolsChanges[_poolId].push(changes);

    emit PoolUpdated(2, _poolId, pools[_poolId], changes, block.number + pools[_poolId].updateDelay);
  }

  // withdraw reward token held in contract
  function retrieveReward(uint16 _poolId, address _to) external onlyOwner {
    _updatePoolInfo(_poolId);
    Pool storage pool = pools[_poolId];
    require(pool.endBlock < block.number, "Staking active");

    _updatePoolRewards(_poolId, block.number);

    uint256 totalPoolRewards = pool.extension.totalPoolRewards;
    uint256 noAddressRewards = pool.extension.noAddressRewards;
    uint256 rewardsWithdrew = pool.extension.rewardsWithdrew;

    uint256 totalUserRewards = pool.extension.totalUserRewards / (10**IERC20Helper(pool.stakeToken).decimals()) / REWARDS_PRECISION;

    require(totalPoolRewards + noAddressRewards > totalUserRewards + rewardsWithdrew, "Insufficient pool rewards");

    uint256 amount = totalPoolRewards + noAddressRewards - totalUserRewards - rewardsWithdrew;

    pool.extension.rewardsWithdrew += amount;

    emit RewardsRetrieved(3, _poolId, msg.sender, _to, amount);

    IERC20(pool.rewardToken).safeTransfer(_to, amount);
  }

  /* Internal */
  function _updatePoolInfo(uint16 _poolId) internal {
    Pool storage pool = pools[_poolId];

    uint256 size = poolsChanges[_poolId].length;
    uint256 i = pool.extension.currentPoolChangeId;
    for (; i < size; i++) {
      PoolChanges storage changes = poolsChanges[_poolId][i];

      uint256 updateAtBlock = changes.blockNumber + pool.updateDelay;
      if (!(pool.endBlock > updateAtBlock && block.number >= updateAtBlock)) {
        break;
      }

      _updatePoolRewards(_poolId, updateAtBlock);
      if (changes.updateParamId == UpdateParam.MaxStakeTokens) {
        pool.maxStakeTokens = changes.updateParamValue;
      } else if (changes.updateParamId == UpdateParam.EndBlock) {
        pool.endBlock = changes.updateParamValue;
      } else if (changes.updateParamId == UpdateParam.RewardTokensPerBlock) {
        pool.rewardTokensPerBlock = changes.updateParamValue;
      }
      changes.applied = true;
    }
    pool.extension.currentPoolChangeId = i;
  }

  function _updatePoolRewards(uint16 _poolId, uint256 _blockNumber) internal {
    Pool storage pool = pools[_poolId];

    Pool memory newPool = _getPoolRewards(pool, _blockNumber);

    pool.accumulatedRewardsPerShare = newPool.accumulatedRewardsPerShare;
    pool.extension.totalUserRewards = newPool.extension.totalUserRewards;
    pool.lastRewardedBlock = newPool.lastRewardedBlock;
  }

  function _getPoolRewards(Pool memory _pool, uint256 _blockNumber) internal pure returns (Pool memory) {
    uint256 floorBlock = _blockNumber <= _pool.endBlock ? _blockNumber : _pool.endBlock;

    if (_pool.tokensStaked == 0) {
      _pool.lastRewardedBlock = floorBlock;
      return _pool;
    }

    uint256 blocksSinceLastReward;
    if (floorBlock >= _pool.lastRewardedBlock) {
      blocksSinceLastReward = floorBlock - _pool.lastRewardedBlock;
    }
    uint256 rewards = blocksSinceLastReward * _pool.rewardTokensPerBlock;
    _pool.accumulatedRewardsPerShare = _pool.accumulatedRewardsPerShare + (rewards / _pool.tokensStaked);
    _pool.lastRewardedBlock = floorBlock;
    _pool.extension.totalUserRewards += rewards;

    return _pool;
  }

  function renounceOwnership() public virtual override onlyOwner {
    revert("Ownable: renounceOwnership function is disabled");
  }
}

interface IERC20Helper {
  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);
}