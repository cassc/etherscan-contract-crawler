// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./vLit.sol";

contract LitStaking is Ownable {
  using SafeERC20 for IERC20;
  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of vLit
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accVLitPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accVLitPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }
  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. vLit to distribute per block.
    uint256 lastRewardBlock; // Last block number that vLit distribution occurs.
    uint256 accVLitPerShare; // Accumulated vLit per share, times 1e12. See below.
  }
  // The vLit Token
  vLit public _vLit;
  // vLit tokens created per block.
  uint256 public vLitPerBlock;
  // Info of each pool.
  PoolInfo[] public poolInfo;
  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  // Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint = 0;
  // The block number when vLit minting starts.
  uint256 public startBlock;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );

  constructor(address vLit_, uint256 _vLitPerBlock, uint256 _startBlock) {
    _vLit = vLit(vLit_);
    vLitPerBlock = _vLitPerBlock;
    startBlock = _startBlock;
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  // Add a new lp to the pool. Can only be called by the owner.
  // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  function add(
    uint256 _allocPoint,
    IERC20 _lpToken,
    bool _withUpdate
  ) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    uint256 lastRewardBlock =
    block.number > startBlock ? block.number : startBlock;
    totalAllocPoint = totalAllocPoint + _allocPoint;
    poolInfo.push(
      PoolInfo({
    lpToken : _lpToken,
    allocPoint : _allocPoint,
    lastRewardBlock : lastRewardBlock,
    accVLitPerShare : 0
    })
    );
  }

  // Update the given pool's vLit allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }

    totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
    poolInfo[_pid].allocPoint = _allocPoint;
  }

  // View function to see pending vLit on frontend.
  function pendingVLit(uint256 _pid, address _user)
  external
  view
  returns (uint256)
  {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accVLitPerShare = pool.accVLitPerShare;
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 elapsedBlocks = block.number - pool.lastRewardBlock;
      uint256 vLitReward = elapsedBlocks * vLitPerBlock * pool.allocPoint / totalAllocPoint;
      accVLitPerShare = accVLitPerShare + (vLitReward * 1e12 / lpSupply);
    }
    return user.amount * accVLitPerShare / 1e12 - user.rewardDebt;
  }

  // Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 elapsedBlocks = block.number - pool.lastRewardBlock;
    uint256 vLitReward = elapsedBlocks * vLitPerBlock * pool.allocPoint / totalAllocPoint;
    _vLit.mint(address(this), vLitReward);
    pool.accVLitPerShare = pool.accVLitPerShare + (vLitReward * 1e12 / lpSupply);
    pool.lastRewardBlock = block.number;
  }

  // Deposit LP tokens to LitStaking for vLit allocation.
  function deposit(uint256 _pid, uint256 _amount) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);
    if (user.amount > 0) {
      uint256 pending = user.amount * pool.accVLitPerShare / 1e12 - user.rewardDebt;
      safeVLitTransfer(msg.sender, pending);
    }
    pool.lpToken.safeTransferFrom(
      address(msg.sender),
      address(this),
      _amount
    );
    user.amount = user.amount + _amount;
    user.rewardDebt = user.amount * pool.accVLitPerShare / 1e12;
    emit Deposit(msg.sender, _pid, _amount);
  }

  // Withdraw LP tokens from LitStaking.
  function withdraw(uint256 _pid, uint256 _amount) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "withdraw: not good");
    updatePool(_pid);
    uint256 pending = user.amount * pool.accVLitPerShare / 1e12 - user.rewardDebt;
    safeVLitTransfer(msg.sender, pending);
    user.amount = user.amount - _amount;
    user.rewardDebt = user.amount * pool.accVLitPerShare / 1e12;
    pool.lpToken.safeTransfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    pool.lpToken.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  // Safe vLit transfer function, just in case if rounding error causes pool to not have enough vLit.
  function safeVLitTransfer(address _to, uint256 _amount) internal {
    uint256 vLitBal = _vLit.balanceOf(address(this));
    if (_amount > vLitBal) {
      _vLit.transfer(_to, vLitBal);
    } else {
      _vLit.transfer(_to, _amount);
    }
  }

  event RewardPerBlockSet(uint256 amount);
  function setVLitPerBlockPerBlock(uint256 _vLitPerBlock) external onlyOwner {
    massUpdatePools();
    vLitPerBlock = _vLitPerBlock;
    emit RewardPerBlockSet(_vLitPerBlock);
  }
}