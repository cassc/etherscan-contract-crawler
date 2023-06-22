// SPDX-License-Identifier: MPL-2.0

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "./StrudelToken.sol";

// The torchship has brought them to Ganymede, where they have to pulverize boulders and lava flows, and seed the resulting dust with carefully formulated organic material.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once STRDLS is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract TorchShip is Initializable, ContextUpgradeSafe, OwnableUpgradeSafe {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Events
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of STRDLs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accStrudelPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accStrudelPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. STRDLs to distribute per block.
    uint256 lastRewardBlock; // Last block number that STRDLs distribution occurs.
    uint256 accStrudelPerShare; // Accumulated STRDLs per share, times 1e12. See below.
  }

  // immutable
  StrudelToken private strudel;

  // governance params
  // Dev fund
  uint256 public devFundDivRate;
  // Block number when bonus STRDL period ends.
  uint256 public bonusEndBlock;
  // STRDL tokens created per block.
  uint256 public strudelPerBlock;
  // Bonus muliplier for early strudel makers.
  uint256 public bonusMultiplier;
  // The block number when STRDL mining starts.
  uint256 public startBlock;

  // working memory
  // Info of each pool.
  PoolInfo[] public poolInfo;
  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  // Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;

  function initialize(
    address _strudel,
    uint256 _strudelPerBlock,
    uint256 _startBlock,
    uint256 _bonusEndBlock,
    uint256 _bonusMultiplier
  ) public initializer {
    __Ownable_init();
    strudel = StrudelToken(_strudel);
    require(_strudelPerBlock >= 10**15, "forgot the decimals for $TRDL?");
    strudelPerBlock = _strudelPerBlock;
    bonusEndBlock = _bonusEndBlock;
    startBlock = _startBlock;
    bonusMultiplier = _bonusMultiplier;
    totalAllocPoint = 0;
    devFundDivRate = 17;
  }

  // Safe strudel transfer function, just in case if rounding error causes pool to not have enough STRDLs.
  function safeStrudelTransfer(address _to, uint256 _amount) internal {
    uint256 strudelBal = strudel.balanceOf(address(this));
    if (_amount > strudelBal) {
      strudel.transfer(_to, strudelBal);
    } else {
      strudel.transfer(_to, _amount);
    }
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  // Return reward multiplier over the given _from to _to block.
  function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
    if (_to <= bonusEndBlock) {
      return _to.sub(_from).mul(bonusMultiplier);
    } else if (_from >= bonusEndBlock) {
      return _to.sub(_from);
    } else {
      return bonusEndBlock.sub(_from).mul(bonusMultiplier).add(_to.sub(bonusEndBlock));
    }
  }

  // View function to see pending STRDLs on frontend.
  function pendingStrudel(uint256 _pid, address _user) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accStrudelPerShare = pool.accStrudelPerShare;
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 strudelReward = multiplier.mul(strudelPerBlock).mul(pool.allocPoint).div(
        totalAllocPoint
      );
      accStrudelPerShare = accStrudelPerShare.add(strudelReward.mul(1e12).div(lpSupply));
    }
    return user.amount.mul(accStrudelPerShare).div(1e12).sub(user.rewardDebt);
  }

  // Update reward vairables for all pools. Be careful of gas spending!
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
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 strudelReward = multiplier.mul(strudelPerBlock).mul(pool.allocPoint).div(
      totalAllocPoint
    );
    strudel.mint(owner(), strudelReward.div(devFundDivRate));
    strudel.mint(address(this), strudelReward);
    pool.accStrudelPerShare = pool.accStrudelPerShare.add(strudelReward.mul(1e12).div(lpSupply));
    pool.lastRewardBlock = block.number;
  }

  // Deposit LP tokens to TorchShip for STRDL allocation.
  function deposit(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);
    if (user.amount > 0) {
      uint256 pending = user.amount.mul(pool.accStrudelPerShare).div(1e12).sub(user.rewardDebt);
      safeStrudelTransfer(msg.sender, pending);
    }
    pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.amount.mul(pool.accStrudelPerShare).div(1e12);
    emit Deposit(msg.sender, _pid, _amount);
  }

  // Withdraw LP tokens from TorchShip.
  function withdraw(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "withdraw: not good");
    updatePool(_pid);
    uint256 pending = user.amount.mul(pool.accStrudelPerShare).div(1e12).sub(user.rewardDebt);
    safeStrudelTransfer(msg.sender, pending);
    user.amount = user.amount.sub(_amount);
    user.rewardDebt = user.amount.mul(pool.accStrudelPerShare).div(1e12);
    pool.lpToken.safeTransfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    pool.lpToken.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  // governance functions:

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
    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    poolInfo.push(
      PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accStrudelPerShare: 0
      })
    );
  }

  // Update the given pool's STRDL allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    poolInfo[_pid].allocPoint = _allocPoint;
  }

  function setDevFundDivRate(uint256 _devFundDivRate) public onlyOwner {
    require(_devFundDivRate > 0, "!devFundDivRate-0");
    devFundDivRate = _devFundDivRate;
  }

  function setBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
    bonusEndBlock = _bonusEndBlock;
  }

  function setStrudelPerBlock(uint256 _strudelPerBlock) public onlyOwner {
    require(_strudelPerBlock > 0, "!strudelPerBlock-0");
    strudelPerBlock = _strudelPerBlock;
  }

  function setBonusMultiplier(uint256 _bonusMultiplier) public onlyOwner {
    require(_bonusMultiplier > 0, "!bonusMultiplier-0");
    bonusMultiplier = _bonusMultiplier;
  }
}