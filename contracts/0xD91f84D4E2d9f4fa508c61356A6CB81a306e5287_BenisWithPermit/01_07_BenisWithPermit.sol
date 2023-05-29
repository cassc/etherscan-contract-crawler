// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BenisWithPermit is Ownable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 remainingWBANReward; // WBAN Tokens that weren't distributed for user per pool.
        //
        // We do some fancy math here. Basically, any point in time, the amount of WBAN
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accWBANPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws Staked tokens to a pool. Here's what happens:
        //   1. The pool's `accWBANPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 stakingToken; // Contract address of staked token
        uint256 stakingTokenTotalAmount; //Total amount of deposited tokens
        uint256 accWBANPerShare; // Accumulated wBAN per share, times 1e12. See below.
        uint32 lastRewardTime; // Last timestamp number that wBAN distribution occurs.
        uint16 allocPoint; // How many allocation points assigned to this pool. wBAN to distribute per second.
    }

    IERC20 public immutable wban; // wBAN TOKEN
    uint256 public wbanPerSecond; // wBAN tokens vested per second
    address private rewardsDistributor;

    PoolInfo[] public poolInfo; // Info of each pool

    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes tokens

    uint256 public totalAllocPoint = 0; // Total allocation points. Must be the sum of all allocation points in all pools

    uint32 public immutable startTime; // The timestamp when wBAN farming starts
    uint32 public endTime; // Time on which the reward calculation should end

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _wban,
        uint256 _wbanPerSecond,
        uint32 _startTime,
        address _rewardsDistributor
    ) {
        wban = _wban;

        wbanPerSecond = _wbanPerSecond;
        startTime = _startTime;
        endTime = _startTime;
        rewardsDistributor = _rewardsDistributor;
    }

    function changeEndTime(uint32 addSeconds) external onlyOwner {
        endTime += addSeconds;
    }

    function reduceEndTime(uint32 subSeconds) external onlyOwner {
        require(endTime - subSeconds >= block.timestamp, "Can't have end time in the past");
        endTime -= subSeconds;
    }

    // Changes wBAN token reward per second. Use this function to moderate the `lockup amount`.
    // Essentially this function changes the amount of the reward which is entitled to the
    // user for his token staking by the time the `endTime` is passed.
    // Good practice to update pools without messing up the contract
    function setWBANPerSecond(uint256 _wbanPerSecond, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        wbanPerSecond = _wbanPerSecond;
    }

    // How many pools are in the contract
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new staking token to the pool. Can only be called by the owner.
    // VERY IMPORTANT NOTICE
    // ----------- DO NOT add the same staking token more than once. Rewards will be messed up if you do. -------------
    // Good practice to update pools without messing up the contract
    function add(
        uint16 _allocPoint,
        IERC20 _stakingToken,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint += _allocPoint;
        poolInfo.push(
            PoolInfo({
                stakingToken: _stakingToken,
                stakingTokenTotalAmount: 0,
                allocPoint: _allocPoint,
                lastRewardTime: uint32(lastRewardTime),
                accWBANPerShare: 0
            })
        );
    }

    function withdrawRewards() external onlyOwner returns (uint256) {
        uint256 wbanBalance = wban.balanceOf(address(this));
        if (wbanBalance > 0) {
            wban.safeTransfer(rewardsDistributor, wbanBalance);
        }
        return wbanBalance;
    }

    // Update the given pool's wBAN allocation point. Can only be called by the owner.
    // Good practice to update pools without messing up the contract
    function set(
        uint256 _pid,
        uint16 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to time.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        _from = _from > startTime ? _from : startTime;
        if (_from > endTime || _to < startTime) {
            return 0;
        }
        if (_to > endTime) {
            return endTime - _from;
        }
        return _to - _from;
    }

    // View function to see pending wBAN on frontend.
    function pendingWBAN(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accWBANPerShare = pool.accWBANPerShare;

        if (block.timestamp > pool.lastRewardTime && pool.stakingTokenTotalAmount != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 wbanReward = multiplier * wbanPerSecond * pool.allocPoint / totalAllocPoint;
            accWBANPerShare += wbanReward * 1e12 / pool.stakingTokenTotalAmount;
        }
        return (user.amount * accWBANPerShare / 1e12) - user.rewardDebt + user.remainingWBANReward;
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
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        if (pool.stakingTokenTotalAmount == 0) {
            pool.lastRewardTime = uint32(block.timestamp);
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 wbanReward = multiplier * wbanPerSecond * pool.allocPoint / totalAllocPoint;
        pool.accWBANPerShare += wbanReward * 1e12 / pool.stakingTokenTotalAmount;
        pool.lastRewardTime = uint32(block.timestamp);
    }

    // Deposit staking tokens to Benis for wBAN rewards.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accWBANPerShare / 1e12) - user.rewardDebt + user.remainingWBANReward;
            user.remainingWBANReward = safeRewardTransfer(msg.sender, pending);
        }
        pool.stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount += _amount;
        pool.stakingTokenTotalAmount += _amount;
        user.rewardDebt = user.amount * pool.accWBANPerShare / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Deposit staking tokens to Benis for wBAN rewards, using EIP712 signatures.
    function depositWithPermit(uint256 _pid, uint256 _amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        IERC20 stakingToken = poolInfo[_pid].stakingToken;
        IERC20Permit(address(stakingToken)).permit(msg.sender, address(this), _amount, deadline, v, r, s);
        deposit(_pid, _amount);
    }

    // Withdraw staked tokens from Benis.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "Benis: not enough LP");
        updatePool(_pid);
        uint256 pending = (user.amount * pool.accWBANPerShare / 1e12) - user.rewardDebt + user.remainingWBANReward;
        user.remainingWBANReward = safeRewardTransfer(msg.sender, pending);
        user.amount -= _amount;
        pool.stakingTokenTotalAmount -= _amount;
        user.rewardDebt = user.amount * pool.accWBANPerShare / 1e12;
        pool.stakingToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 userAmount = user.amount;
        pool.stakingTokenTotalAmount -= userAmount;
        delete userInfo[_pid][msg.sender];
        pool.stakingToken.safeTransfer(address(msg.sender), userAmount);
        emit EmergencyWithdraw(msg.sender, _pid, userAmount);
    }

    // Safe wBAN transfer function. Just in case if the pool does not have enough wBAN token,
    // The function returns the amount which is owed to the user
    function safeRewardTransfer(address _to, uint256 _amount) internal returns (uint256) {
        uint256 wbanBalance = wban.balanceOf(address(this));
        if (wbanBalance == 0) {
            //save some gas fee
            return _amount;
        }
        if (_amount > wbanBalance) {
            wban.safeTransfer(_to, wbanBalance);
            return _amount - wbanBalance;
        }
        wban.safeTransfer(_to, _amount);
        return 0;
    }
}