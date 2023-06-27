// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './libraries/SignedSafeMath.sol';
import './libraries/SafeMath.sol';
import './MIRLERC20.sol';
import './IMIRLStaking.sol';
import './IMigratorChef.sol';
import 'hardhat/console.sol';

contract MirlStaking is Ownable, IMIRLStaking {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  /// @notice Info of each MirlStaking user.
  /// `amount` LP token amount the user has provided.
  /// `rewardDebt` The amount of MIRL entitled to the user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    int256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  /// @notice Info of each MirlStaking pool.
  /// `allocPoint` The amount of allocation points assigned to the pool.
  /// Also known as the amount of MIRL to distribute per block.
  struct PoolInfo {
    uint256 accumulatedMirlPerShare;
    uint64 lastRewardBlock;
    uint64 allocPoint;
    uint256 totalSupply;
  }

  /// @notice Address of MIRL contract.
  MadeInRealLife public immutable MIRL;
  /// @notice The migrator contract. It has a lot of power. Can only be set through governance (owner).
  IMigratorChef public migrator;
  // MIRL tokens created per block.
  uint256 public mirlPerBlock;

  // Block number when bonus start
  uint256 public bonusStartBlock;
  // Block number when bonus period ends.
  uint256 public bonusEndBlock;

  /// @notice Info of each MirlStaking pool.
  PoolInfo[] public poolInfo;
  /// @notice Address of the LP token for each MirlStaking pool.
  IERC20[] public lpToken;

  /// @notice Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint = 0;

  // uint256 private constant MASTERCHEF_SUSHI_PER_BLOCK = 1e20;
  uint256 private constant ACC_SUSHI_PRECISION = 1e18;

  /// @param _mirl The MIRL token contract address.
  constructor(MadeInRealLife _mirl) {
    MIRL = _mirl;
  }

  /// @notice Add a new LP to the pool. Can only be called by the owner.
  /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  /// @param allocPoint AP of the new pool.
  /// @param _lpToken Address of the LP ERC-20 token.
  function add(uint256 allocPoint, IERC20 _lpToken) public onlyOwner {
    bool existToken = false;
    uint256 len = lpToken.length;
    for (uint256 i = 0; i < len; ++i) {
      if (lpToken[i] == _lpToken) existToken = true;
    }
    require(!existToken, 'Pool is existed');
    uint256 lastBlock = block.number > bonusStartBlock ? block.number : bonusStartBlock;
    totalAllocPoint = totalAllocPoint.add(allocPoint);
    lpToken.push(_lpToken);

    poolInfo.push(
      PoolInfo({
        allocPoint: allocPoint.to64(),
        lastRewardBlock: lastBlock.to64(),
        accumulatedMirlPerShare: 0,
        totalSupply: 0
      })
    );
    emit LogPoolAddition(lpToken.length.sub(1), allocPoint, _lpToken);
  }

  /// @notice Update the given pool's MIRL allocation point. Can only be called by the owner.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _allocPoint New AP of the pool.
  function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    poolInfo[_pid].allocPoint = _allocPoint.to64();
    emit LogSetPool(_pid, _allocPoint);
  }

  /// @notice Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    uint256 len = poolInfo.length;
    for (uint256 i = 0; i < len; ++i) {
      updatePool(i);
    }
  }

  /* MIRLStaking */
  /// @notice Update reward variables of the given pool.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @return pool Returns the pool that was updated.
  function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
    require(pid < poolInfo.length, 'Invalid pool id');
    pool = poolInfo[pid];
    uint256 startBlockPeriod = pool.lastRewardBlock > bonusStartBlock ? pool.lastRewardBlock : bonusStartBlock;
    uint256 endBlockPeriod = (bonusEndBlock == 0 || block.number < bonusEndBlock) ? block.number : bonusEndBlock;
    uint256 lpSupply = pool.totalSupply;

    if (startBlockPeriod < endBlockPeriod && lpSupply > 0) {
      // blocksCount
      uint256 blocks = endBlockPeriod.sub(startBlockPeriod);
      uint256 mirlReward = blocks.mul(mirlPerBlock).mul(pool.allocPoint) / totalAllocPoint;
      MIRL.mint(address(this), mirlReward);

      pool.accumulatedMirlPerShare = pool.accumulatedMirlPerShare.add((mirlReward.mul(ACC_SUSHI_PRECISION) / lpSupply));
    }
    pool.lastRewardBlock = block.number.to64();
    poolInfo[pid] = pool;
    emit LogUpdatePool(pid, pool.lastRewardBlock, lpSupply, pool.accumulatedMirlPerShare);
  }

  /// @notice Deposit LP tokens to MirlStaking for MIRL allocation.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount LP token amount to deposit.
  function deposit(uint256 pid, uint256 amount) public {
    require(pid < poolInfo.length, 'pool id is not existed');
    PoolInfo memory pool = updatePool(pid);
    UserInfo storage user = userInfo[pid][msg.sender];

    // Effects
    user.amount = user.amount.add(amount);
    user.rewardDebt = user.rewardDebt.add(int256(amount.mul(pool.accumulatedMirlPerShare) / ACC_SUSHI_PRECISION));

    // Interactions
    // lpToken[pid].safeTransferFrom(msg.sender, amount);
    lpToken[pid].transferFrom(msg.sender, address(this), amount);
    poolInfo[pid].totalSupply = pool.totalSupply.add(amount);
    emit Deposit(msg.sender, pid, amount);
  }

  /// @notice View function to see pending MIRL on frontend.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _user Address of user.
  /// @return pending MIRL reward for a given user.
  function pendingMirl(uint256 _pid, address _user) external view returns (uint256 pending) {
    PoolInfo memory pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 poolMirlPerShare = pool.accumulatedMirlPerShare;
    uint256 lpSupply = pool.totalSupply;

    uint256 startBlockPeriod = pool.lastRewardBlock > bonusStartBlock ? pool.lastRewardBlock : bonusStartBlock;
    uint256 endBlockPeriod = (bonusEndBlock == 0 || block.number < bonusEndBlock) ? block.number : bonusEndBlock;

    if (endBlockPeriod > startBlockPeriod && lpSupply != 0) {
      uint256 blocks = endBlockPeriod.sub(startBlockPeriod);
      uint256 mirlReward = blocks.mul(mirlPerBlock).mul(pool.allocPoint) / totalAllocPoint;
      poolMirlPerShare = poolMirlPerShare.add(mirlReward.mul(ACC_SUSHI_PRECISION) / lpSupply);
    }
    pending = int256(user.amount.mul(poolMirlPerShare) / ACC_SUSHI_PRECISION).sub(user.rewardDebt).toUInt256();
  }

  /// @notice Withdraw LP tokens from MirlStaking.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount LP token amount to withdraw.
  function withdraw(uint256 pid, uint256 amount) public {
    require(pid < poolInfo.length, 'invalid pool id');
    UserInfo storage user = userInfo[pid][msg.sender];

    require(user.amount > amount, 'invalid amount');
    PoolInfo memory pool = updatePool(pid);

    // Effects
    user.rewardDebt = user.rewardDebt.sub(int256(amount.mul(pool.accumulatedMirlPerShare) / ACC_SUSHI_PRECISION));
    user.amount = user.amount.sub(amount);
    poolInfo[pid].totalSupply = poolInfo[pid].totalSupply.sub(amount);
    // Interactions
    lpToken[pid].safeTransfer(msg.sender, amount);

    emit Withdraw(msg.sender, pid, amount);
  }

  /// @notice Harvest proceeds for transaction sender to `to`.
  /// @param pid The index of the pool. See `poolInfo`.
  function harvest(uint256 pid) public {
    PoolInfo memory pool = updatePool(pid);
    UserInfo storage user = userInfo[pid][msg.sender];
    int256 accumulatedMirl = int256(user.amount.mul(pool.accumulatedMirlPerShare) / ACC_SUSHI_PRECISION);
    uint256 _pendingMirl = accumulatedMirl.sub(user.rewardDebt).toUInt256();

    // Effects
    user.rewardDebt = accumulatedMirl;

    // Interactions
    if (_pendingMirl != 0) {
      MIRL.transfer(msg.sender, _pendingMirl);
    }

    emit Harvest(msg.sender, pid, _pendingMirl);
  }

  /// @notice Withdraw LP tokens from MirlStaking and harvest proceeds for transaction sender to `to`.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount LP token amount to withdraw.
  function withdrawAndHarvest(uint256 pid, uint256 amount) public {
    require(pid < poolInfo.length, 'invalid pool id');
    UserInfo storage user = userInfo[pid][msg.sender];

    require(user.amount > amount, 'invalid amount');

    PoolInfo memory pool = updatePool(pid);
    int256 accumulatedMirl = int256(user.amount.mul(pool.accumulatedMirlPerShare) / ACC_SUSHI_PRECISION);
    uint256 _pendingMirl = accumulatedMirl.sub(user.rewardDebt).toUInt256();

    // Effects
    user.rewardDebt = accumulatedMirl.sub(int256(amount.mul(pool.accumulatedMirlPerShare) / ACC_SUSHI_PRECISION));
    user.amount = user.amount.sub(amount);

    // Interactions
    MIRL.transfer(msg.sender, _pendingMirl);
    lpToken[pid].safeTransfer(msg.sender, amount);
    poolInfo[pid].totalSupply = poolInfo[pid].totalSupply.sub(amount);
    emit Withdraw(msg.sender, pid, amount);
    emit Harvest(msg.sender, pid, _pendingMirl);
  }

  /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
  /// @param pid The index of the pool. See `poolInfo`.
  function emergencyWithdraw(uint256 pid) public {
    UserInfo storage user = userInfo[pid][msg.sender];
    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;

    // Note: transfer can fail or succeed if `amount` is zero.
    lpToken[pid].safeTransfer(msg.sender, amount);
    poolInfo[pid].totalSupply = poolInfo[pid].totalSupply.sub(amount);
    emit EmergencyWithdraw(msg.sender, pid, amount);
  }

  /// @notice Set the `migrator` contract. Can only be called by the owner.
  /// @param _migrator The contract address to set.
  function setMigrator(IMigratorChef _migrator) public onlyOwner {
    migrator = _migrator;
  }

  /// @notice Migrate LP token to another LP contract through the `migrator` contract.
  /// @param _pid The index of the pool. See `poolInfo`.
  function migrate(uint256 _pid) public {
    require(address(migrator) != address(0), 'MirlStaking: no migrator set');
    IERC20 _lpToken = lpToken[_pid];
    uint256 bal = _lpToken.balanceOf(address(this));
    _lpToken.approve(address(migrator), bal);
    IERC20 newLpToken = migrator.migrate(_lpToken);
    require(bal == newLpToken.balanceOf(address(this)), 'MirlStaking: migrated balance must match');
    lpToken[_pid] = newLpToken;
  }

  function setBonusStartBlock(uint256 number) public onlyOwner {
    require(bonusEndBlock == 0 || number < bonusEndBlock, 'Start block must to lesser than end block');
    bonusStartBlock = number;
    massUpdatePools();
  }

  function setBonusEndBlock(uint256 number) public onlyOwner {
    require(number == 0 || number > bonusStartBlock, 'End block must to greater than start block');
    bonusEndBlock = number;
    massUpdatePools();
  }

  function setMIRLPerBlock(uint256 number) public onlyOwner {
    mirlPerBlock = number;
    massUpdatePools();
  }

  /// @notice Returns the number of MirlStaking pools.
  function poolLength() public view returns (uint256 pools) {
    pools = poolInfo.length;
  }

  function balanceOf(uint256 pid, address user) public view returns (uint256) {
    return userInfo[pid][user].amount;
  }

  function rewardDebt(uint256 pid, address user) public view returns (int256) {
    return userInfo[pid][user].rewardDebt;
  }

  function accumulatedMirlPerShare(uint256 pid) public view returns (uint256) {
    return poolInfo[pid].accumulatedMirlPerShare;
  }

  function lastRewardBlock(uint256 pid) public view returns (uint256) {
    return poolInfo[pid].lastRewardBlock;
  }
}