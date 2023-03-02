// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-new/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-new/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-new/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-new/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-new/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable-new/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-new/proxy/utils/Initializable.sol";
import { ERC20VotesUpgradeable } from "./ERC20VotesUpgradeable.sol";
import { ZERO } from "./ZERO.sol";
import { SplitSignatureLib } from "../util/SplitSignatureLib.sol";
import { IERC20Permit } from "@openzeppelin/contracts-new/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IMigratorChef {
  // Perform LP token migration from legacy UniswapV2 to ZeroSwap.
  // Take the current LP token address and return the new LP token address.
  // Migrator should have full access to the caller's LP token.
  // Return the new LP token address.
  //
  // XXX Migrator must have allowance access to UniswapV2 LP tokens.
  // ZeroSwap must mint EXACTLY the same amount of ZeroSwap LP tokens or
  // else something bad will happen. Traditional UniswapV2 does not
  // do that so be careful!
  function migrate(IERC20 token) external returns (IERC20);
}

// MasterChef is the master of sZero. He can make sZero and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSHI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract sZERO is Initializable, OwnableUpgradeable, ERC20VotesUpgradeable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accZeroPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accZeroPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
    uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
    uint256 accZeroPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
  }

  struct ZAsset {
    IERC20 token;
    uint256 rewardsToBeMinted;
    uint256 multiplier;
  }

  // The ZERO TOKEN!
  ZERO public zero;
  // Dev address.
  address public devaddr;
  // Block number when bonus SUSHI period ends.
  uint256 public bonusEndBlock;
  // SUSHI tokens created per block.
  uint256 public zeroPerBlock;

  // Bonus muliplier for early zero makers.
  uint256 public constant BONUS_MULTIPLIER = 10;
  // The migrator contract. It has a lot of power. Can only be set through governance (owner).
  IMigratorChef public migrator;
  // Info of each pool.
  PoolInfo[] public poolInfo;

  ZAsset[] public zassets;
  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint = 0;
  // The block number when SUSHI mining starts.
  //
  mapping(address => bool) isZAsset;
  uint256 constant ZERO_POOL = 0;
  uint256 public startBlock;
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

  // Add a new lp to the pool. Can only be called by the owner.
  // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  // initializes zero pool
  // function addZeroPool(
  //   uint256 _allocPoint,
  //   IERC20 _lpToken,
  //   bool _withUpdate
  // ) public onlyOwner {
  //   if (_withUpdate) {
  //     massUpdatePools();
  //   }
  //   uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
  //   totalAllocPoint = totalAllocPoint.add(_allocPoint);
  //   poolInfo[ZERO_POOL] = PoolInfo({
  //     lpToken: _lpToken,
  //     allocPoint: _allocPoint,
  //     lastRewardBlock: lastRewardBlock,
  //     accZeroPerShare: 0
  //   });
  // }

  function initialize(
    ZERO _zero,
    address zerofrost,
    address _devaddr,
    uint256 _zeroPerBlock,
    uint256 _bonusEndBlock
  ) public initializer {
    zero = _zero;
    devaddr = _devaddr;
    zeroPerBlock = _zeroPerBlock;
    bonusEndBlock = block.number + _bonusEndBlock;
    startBlock = block.number;
    __Ownable_init_unchained();
    __ERC20_init_unchained("sZERO", "sZERO");
    __ERC20Votes_init_unchained(zerofrost);
    // init pool
    totalAllocPoint = totalAllocPoint.add(1 ether);
    poolInfo.push(
      PoolInfo({
        lpToken: IERC20(address(_zero)),
        allocPoint: 1 ether,
        lastRewardBlock: block.number,
        accZeroPerShare: 0
      })
    );
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  // Update the given pool's SUSHI allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) public onlyOwner {
    if (_withUpdate) {
      //massUpdatePools();
      updateZeroPool();
    }
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    poolInfo[_pid].allocPoint = _allocPoint;
  }

  // Set the migrator contract. Can only be called by the owner.
  function setMigrator(IMigratorChef _migrator) public onlyOwner {
    migrator = _migrator;
  }

  // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
  function migrate(uint256 _pid) public {
    require(address(migrator) != address(0), "migrate: no migrator");
    PoolInfo storage pool = poolInfo[_pid];
    IERC20 lpToken = pool.lpToken;
    uint256 bal = lpToken.balanceOf(address(this));
    lpToken.safeApprove(address(migrator), bal);
    IERC20 newLpToken = migrator.migrate(lpToken);
    require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
    pool.lpToken = newLpToken;
  }

  // Return reward multiplier over the given _from to _to block.
  function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
    if (_to <= bonusEndBlock) {
      return _to.sub(_from).mul(BONUS_MULTIPLIER);
    } else if (_from >= bonusEndBlock) {
      return _to.sub(_from);
    } else {
      return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(_to.sub(bonusEndBlock));
    }
  }

  //TODO: rework this a bit
  function calculateZeroReward(uint256 multiplier, uint256 lpSupply) public view returns (uint256 zeroReward) {
    zeroReward = multiplier.mul(zeroPerBlock).mul(lpSupply).div(1 ether);
    for (uint256 i = 0; i < zassets.length; i++) {
      ZAsset storage zAsset = zassets[i];
      zeroReward = zeroReward.add(zAsset.rewardsToBeMinted.mul(zAsset.multiplier).div(1 ether));
    }
  }

  // View function to see pending SUSHIs on frontend.
  function pendingZero(uint256 _pid, address _user) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accZeroPerShare = pool.accZeroPerShare;
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 zeroReward = calculateZeroReward(multiplier, lpSupply);
      accZeroPerShare = accZeroPerShare.add(zeroReward.mul(1e12).div(lpSupply));
    }
    return user.amount.mul(accZeroPerShare).div(1e12).sub(user.rewardDebt);
  }

  // // Update reward vairables for all pools. Be careful of gas spending!
  // function massUpdatePools() public {
  //   uint256 length = poolInfo.length;
  //   for (uint256 pid = 0; pid < length; ++pid) {
  //     updatePool(pid);
  //   }
  // }
  // callback on transfer/transferfrom of the zasset token
  function updateZAssetReward(uint256 idx, uint256 amount) external {
    ZAsset storage zAsset = zassets[idx];
    require(msg.sender == address(zAsset.token));
    zAsset.rewardsToBeMinted = zAsset.rewardsToBeMinted.add(amount);
  }

  // Update reward variables of the given pool to be up-to-date.
  function updateZeroPool() public {
    PoolInfo storage pool = poolInfo[0];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 zeroReward = calculateZeroReward(multiplier, lpSupply);
    zero.mint(devaddr, zeroReward.div(10));
    zero.mint(address(this), zeroReward);
    pool.accZeroPerShare = pool.accZeroPerShare.add(zeroReward.mul(1e12).div(lpSupply));
    pool.lastRewardBlock = block.number;
  }

  // Deposit LP tokens to MasterChef for SUSHI allocation.
  function deposit(uint256 _pid, uint256 _amount) internal returns (uint256 pending) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updateZeroPool();
    if (user.amount > 0) {
      pending = user.amount.mul(pool.accZeroPerShare).div(1e12).sub(user.rewardDebt);
      safeZeroTransfer(msg.sender, pending);
    }
    pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.amount.mul(pool.accZeroPerShare).div(1e12);
    emit Deposit(msg.sender, _pid, _amount);
  }

  function enterStaking(uint256 zeroAmount) public {
    deposit(ZERO_POOL, zeroAmount);
    _mint(msg.sender, zeroAmount);
  }

  function enterStakingWithPermit(uint256 zeroAmount, bytes memory sig) public {
    (uint8 v, bytes32 r, bytes32 s) = SplitSignatureLib.splitSignature(sig);
    zero.permit(
      msg.sender,
      address(this),
      zeroAmount,
      uint256(keccak256(abi.encodePacked(msg.sender, address(this), zeroAmount, zero.nonces(msg.sender)))),
      v,
      r,
      s
    );
    enterStaking(zeroAmount);
  }

  function leaveStaking(uint256 zeroAmount) public {
    withdraw(ZERO_POOL, zeroAmount);
    _burn(msg.sender, zeroAmount);
  }

  function redeem() public {
    deposit(ZERO_POOL, 0);
  }

  function transfer(address sender, uint256 amount) public override returns (bool) {
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override returns (bool) {
    return true;
  }

  // Withdraw LP tokens from MasterChef.
  function withdraw(uint256 _pid, uint256 _amount) internal {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "withdraw: not good");
    updateZeroPool();
    // calculate accrued share and remove previously withdrawn rewards
    uint256 pending = user.amount.mul(pool.accZeroPerShare).div(1e12).sub(user.rewardDebt);
    safeZeroTransfer(msg.sender, pending);
    user.amount = user.amount.sub(_amount);
    // update previously drawn rewards in terms of current amount
    user.rewardDebt = user.amount.mul(pool.accZeroPerShare).div(1e12);
    pool.lpToken.safeTransfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw() public {
    PoolInfo storage pool = poolInfo[ZERO_POOL];
    UserInfo storage user = userInfo[ZERO_POOL][msg.sender];
    pool.lpToken.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, ZERO_POOL, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  // Safe zero transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
  function safeZeroTransfer(address _to, uint256 _amount) internal {
    uint256 zeroBal = zero.balanceOf(address(this));
    if (_amount > zeroBal) {
      zero.transfer(_to, zeroBal);
    } else {
      zero.transfer(_to, _amount);
    }
  }

  // Update dev address by the previous dev.
  function dev(address _devaddr) public {
    require(msg.sender == devaddr, "dev: wut?");
    devaddr = _devaddr;
  }
}