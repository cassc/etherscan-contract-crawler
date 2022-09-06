// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./utils/PriceCalculator.sol";

contract TheMidasTouchMasterChef is Ownable, ReentrancyGuard, PriceCalculator {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 multipliedAmount;
        //
        // We do some fancy math here. Basically, any point in time, the amount of BCHIEFs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accGoldPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accGoldPerShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token;           // Address of token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BCHIEFs to distribute per block.
        uint256 lastRewardTimestamp;  // Last block number that BCHIEFs distribution occurs.
        uint256 accGoldPerShare;   // Accumulated BCHIEFs per share, times 1e12. See below.
        uint256 harvestInterval;  // Harvest interval in seconds
        uint256 tvl;
        uint256 totalMultipliedSupply;
        uint16 withdrawFeeBP;
    }

    enum Tier {
        STANDARD,
        ADVANCED,
        DAO,
        DAO_PLUS
    }

    // The GOLD TOKEN!
    IERC20 public goldToken;

    // GOLD tokens created per block.
    uint256 public goldRewardPerSec;
    // Bonus muliplier for early goldToken makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // tier reward multiplier
    mapping (uint256 => uint256) public tierMutiplier;
    mapping (uint256 => uint256) public tierStartBlance;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public stakerCount;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when GOLD mining starts.
    uint256 public startTimestamp;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    bool public shouldUpdatePoolsByUser;

    address public feeRecipient;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);

    constructor(
        IERC20 _gold,
        uint256 _startTimestamp,
        uint256 _goldPerSec
    ) public {
        goldToken = _gold;
        startTimestamp = _startTimestamp;
        goldRewardPerSec = _goldPerSec;
        feeRecipient = msg.sender;
        tierMutiplier[uint(Tier.STANDARD)] = 100;
        tierMutiplier[uint(Tier.ADVANCED)] = 125;
        tierMutiplier[uint(Tier.DAO)] = 150;
        tierMutiplier[uint(Tier.DAO_PLUS)] = 200;
        tierStartBlance[uint(Tier.STANDARD)] = 0;
        tierStartBlance[uint(Tier.ADVANCED)] = 10_000_000 * 1e18;
        tierStartBlance[uint(Tier.DAO)] = 100_000_000 * 1e18;
        tierStartBlance[uint(Tier.DAO_PLUS)] = 2_000_000_000 * 1e18;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _token, uint256 _harvestInterval, uint16 _withdrawFeeBP, bool _withUpdate) public onlyOwner {
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        require(_withdrawFeeBP < 10000, 'invalid withdraw fee');
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            token: _token,
            allocPoint: _allocPoint,
            lastRewardTimestamp: lastRewardTimestamp,
            accGoldPerShare: 0,
            harvestInterval: _harvestInterval,
            tvl: 0,
            totalMultipliedSupply: 0,
            withdrawFeeBP: _withdrawFeeBP
        }));
    }

    // Update the given pool's GOLD allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _harvestInterval, uint16 _withdrawFeeBP, bool _withUpdate) public onlyOwner {
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");
        require(_withdrawFeeBP < 10000, 'invalid withdraw fee');
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].withdrawFeeBP = _withdrawFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return (_to - _from) * BONUS_MULTIPLIER;
    }

    // View function to see pending BCHIEFs on frontend.
    function pendingGold(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGoldPerShare = pool.accGoldPerShare;
        if (block.timestamp > pool.lastRewardTimestamp && pool.totalMultipliedSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
            uint256 goldReward = multiplier * goldRewardPerSec * pool.allocPoint / totalAllocPoint;
            accGoldPerShare = accGoldPerShare + goldReward * 1e12 / pool.totalMultipliedSupply;
        }
        uint256 pending = user.multipliedAmount * accGoldPerShare / 1e12 - user.rewardDebt;
        return pending + user.rewardLockedUp;
    }

    // View function to see if user can harvest BCHIEFs.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    function tvl(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.tvl * getTokenPriceInEthPair(IUniswapV2Router02(uniswapRouter), address(goldToken)) / 1e18;
    }

    function apr(uint256 _pid) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 reward = uint256(86400) * 365 * goldRewardPerSec * pool.allocPoint / totalAllocPoint;
        if (reward > 0) {
            return tvl(_pid) > 0 ? reward * getTokenPriceInEthPair(IUniswapV2Router02(uniswapRouter), address(goldToken)) / tvl(_pid) : 0;
        }
        return 0;
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
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        if (pool.totalMultipliedSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
        uint256 goldReward = multiplier * goldRewardPerSec * pool.allocPoint / totalAllocPoint;
        pool.accGoldPerShare = pool.accGoldPerShare + goldReward * 1e12 / pool.totalMultipliedSupply;
        pool.lastRewardTimestamp = block.timestamp;
    }

    // Deposit tokens for GOLD allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount == 0) {
            stakerCount++;
        }
        if (shouldUpdatePoolsByUser) {
          updatePool(_pid);
        }
        payOrLockupPendingGold(_pid);
        uint userMultipliedAmountBefore = user.multipliedAmount;
        if (_amount > 0) {
            uint transferredAmount = deflationaryTokenTransfer(pool.token, address(msg.sender), address(this), _amount);
            user.amount = user.amount + transferredAmount;
            uint256 mul = getTierMultiply(user.amount);
            user.multipliedAmount = user.amount * mul / 100;
            if (userMultipliedAmountBefore > 0) {
                pool.totalMultipliedSupply = pool.totalMultipliedSupply - userMultipliedAmountBefore + user.multipliedAmount;
            } else {
                pool.totalMultipliedSupply = pool.totalMultipliedSupply + user.multipliedAmount;
            }
            pool.tvl = pool.tvl + transferredAmount;
        }
        user.rewardDebt = user.multipliedAmount * pool.accGoldPerShare / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        payOrLockupPendingGold(_pid);
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            if (user.amount == 0) {
                stakerCount--;
            }
            uint256 mul = getTierMultiply(user.amount);
            pool.totalMultipliedSupply = pool.totalMultipliedSupply - user.multipliedAmount + user.amount * mul / 100;
            pool.tvl = pool.tvl - _amount;
            user.multipliedAmount = user.amount * mul / 100;
            if (pool.withdrawFeeBP > 0) {
                uint256 feeAmount = _amount * pool.withdrawFeeBP / 10000;
                pool.token.safeTransfer(feeRecipient, feeAmount);
                _amount = _amount - feeAmount;
            }
            pool.token.safeTransfer(msg.sender, _amount);
        }
        user.rewardDebt = user.multipliedAmount * pool.accGoldPerShare / 1e12;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.token.safeTransfer(address(msg.sender), amount);
        pool.tvl = pool.tvl - amount;
        pool.totalMultipliedSupply = pool.totalMultipliedSupply - user.multipliedAmount;
        user.multipliedAmount = 0;
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function emergencyWithdrawGold() public onlyOwner {
        PoolInfo memory pool = poolInfo[0];
        uint256 balance = goldToken.balanceOf(address(this));
        if (balance > pool.tvl) {
            balance = balance - pool.tvl;
            safeGoldTransfer(msg.sender, balance);
        }
    }

    // Pay or lockup pending gold.
    function payOrLockupPendingGold(uint256 _pid) internal {
      PoolInfo storage pool = poolInfo[_pid];
      UserInfo storage user = userInfo[_pid][msg.sender];

      if (user.nextHarvestUntil == 0) {
        user.nextHarvestUntil = block.timestamp + pool.harvestInterval;
      }

      uint256 pending = user.multipliedAmount * pool.accGoldPerShare / 1e12 - user.rewardDebt;
      if (canHarvest(_pid, msg.sender)) {
        if (pending > 0 || user.rewardLockedUp > 0) {
          uint256 totalRewards = pending + user.rewardLockedUp;

          // reset lockup
          totalLockedUpRewards = totalLockedUpRewards - user.rewardLockedUp;
          user.rewardLockedUp = 0;
          user.nextHarvestUntil = block.timestamp + pool.harvestInterval;

          // send rewards
          safeGoldTransfer(msg.sender, totalRewards);
        }
      } else if (pending > 0) {
        user.rewardLockedUp = user.rewardLockedUp + pending;
        totalLockedUpRewards = totalLockedUpRewards + pending;
        emit RewardLockedUp(msg.sender, _pid, pending);
      }
    }

    // Safe goldToken transfer function, just in case if rounding error causes pool to not have enough BCHIEFs.
    function safeGoldTransfer(address _to, uint256 _amount) internal {
        uint256 goldBal = goldToken.balanceOf(address(this));
        if (_amount > goldBal) {
            goldToken.transfer(_to, goldBal);
        } else {
            goldToken.transfer(_to, _amount);
        }
    }

    function getTierMultiply(uint256 amount) internal view returns (uint256) {
        uint256 multiply = 1;
        if (amount < tierStartBlance[uint256(Tier.ADVANCED)]) {
            multiply = tierMutiplier[uint256(Tier.STANDARD)];
        } else if (amount >= tierStartBlance[uint256(Tier.ADVANCED)] && amount < tierStartBlance[uint256(Tier.DAO)]) {
            multiply = tierMutiplier[uint256(Tier.ADVANCED)];
        } else if (amount >= tierStartBlance[uint256(Tier.DAO)] && amount < tierStartBlance[uint256(Tier.DAO_PLUS)]) {
            multiply = tierMutiplier[uint256(Tier.DAO)];
        } else {
            multiply = tierMutiplier[uint256(Tier.DAO_PLUS)];
        }

        return multiply;
    }

    // Safe goldToken transfer function, just in case if rounding error causes pool to not have enough BCHIEFs.
    function deflationaryTokenTransfer(IERC20 _token, address _from, address _to, uint256 _amount) internal returns (uint256) {
        uint256 beforeBal = _token.balanceOf(_to);
        _token.safeTransferFrom(_from, _to, _amount);
        uint256 afterBal = _token.balanceOf(_to);
        if (afterBal > beforeBal) {
          return afterBal - beforeBal;
        }
        return 0;
    }

    // Pancake has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _goldPerSec) public onlyOwner {
      massUpdatePools();
      emit EmissionRateUpdated(msg.sender, goldRewardPerSec, _goldPerSec);
      goldRewardPerSec = _goldPerSec;
    }

    function setShouldUpdatePoolsByUser(bool _yesOrNo) external onlyOwner {
      shouldUpdatePoolsByUser = _yesOrNo;
    }
}