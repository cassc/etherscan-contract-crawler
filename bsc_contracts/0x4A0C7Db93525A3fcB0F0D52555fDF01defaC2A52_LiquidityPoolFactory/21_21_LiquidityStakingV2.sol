//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LiquidityStakingV2 is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct UserInfo {
        uint256 amount;
        uint256 shares;
        uint256 rewardDebt;
        uint256 pendingRewards;
        uint256 depositedAt;
        uint256 claimedAt;
        uint256 unlockedAt;
    }

    struct PoolInfo {
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accEulerPerShare;
        uint256 totalSupply;
        uint256 rewardsAmount;
        uint256 lockupDuration;
    }

    IERC20 public immutable lpToken;
    IERC20 public immutable rewardToken;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    EnumerableSet.AddressSet users;
    uint256 public totalAllocPoint;

    uint256 public rewardRate;
    uint256 public unlockDuration;
    uint256 public claimTimes;

    address public factory;

    uint public startTime;
    uint public endTime;

    event Deposit(uint pid, address indexed user, uint amount);
    event Unlock(uint pid, address indexed user, uint amount);
    event Withdraw(uint pid, address indexed user, uint amount);
    event Claim(uint pid, address indexed user, uint amount);

    modifier updateReward(uint pid) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        if (pool.lastRewardTime <= block.timestamp && rewardRate > 0) {
            if (pool.totalSupply > 0) {
                uint256 multiplier = Math.min(block.timestamp, endTime).sub(
                    pool.lastRewardTime
                );
                uint256 rewards = multiplier
                    .mul(rewardRate)
                    .mul(pool.allocPoint)
                    .div(totalAllocPoint);
                pool.rewardsAmount = pool.rewardsAmount.add(rewards);
                pool.accEulerPerShare = pool.accEulerPerShare.add(
                    rewards.mul(1e12).div(pool.totalSupply)
                );
            }
            pool.lastRewardTime = Math.min(block.timestamp, endTime);

            uint256 pending = user
                .amount
                .mul(pool.accEulerPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            user.pendingRewards = user.pendingRewards.add(pending);
        }

        _;

        if (pool.lastRewardTime <= block.timestamp) {
            user.rewardDebt = user.amount.mul(pool.accEulerPerShare).div(1e12);
            if (user.claimedAt == 0) user.claimedAt = block.timestamp;
        }
    }

    modifier updateUserList() {
        _;
        bool staked = false;
        for (uint i = 0; i < poolInfo.length; i++) {
            if (userInfo[i][msg.sender].amount > 0) {
                _checkOrAddUser(msg.sender);
                staked = true;
                break;
            }
        }
        if (staked == false) _removeUser(msg.sender);
    }

    modifier onlyFactory() {
        require(msg.sender == owner() || msg.sender == factory, "!permission");
        _;
    }

    constructor(address _lp, address _reward) {
        lpToken = IERC20(_lp);
        rewardToken = IERC20(_reward);

        factory = msg.sender;
        _pause();
    }

    function initialize(uint _startTime, uint _endTime) external onlyOwner {
        require(_endTime > _startTime, "!end time");

        addPool(1, 0, _startTime);
        addPool(2, 30 days, _startTime);
        addPool(3, 90 days, _startTime);
        addPool(5, 180 days, _startTime);

        startTime = _startTime;
        endTime = _endTime;
    }

    function addPool(
        uint256 _allocPoint,
        uint256 _lockupDuration,
        uint256 _startTime
    ) public onlyOwner {
        require(_startTime >= block.timestamp, "!start time");

        poolInfo.push(
            PoolInfo({
                allocPoint: _allocPoint,
                lastRewardTime: _startTime,
                accEulerPerShare: 0,
                totalSupply: 0,
                rewardsAmount: 0,
                lockupDuration: _lockupDuration
            })
        );

        totalAllocPoint += _allocPoint;
    }

    function setPool(
        uint _pid,
        uint _allocPoint,
        uint _lockupDuration
    ) external onlyOwner {
        updateAllPools();
        PoolInfo storage pool = poolInfo[_pid];
        totalAllocPoint = totalAllocPoint - pool.allocPoint + _allocPoint;
        pool.lockupDuration = _lockupDuration;
        pool.allocPoint = _allocPoint;
    }

    function setStartTime(
        uint _pid,
        uint _startTimeInMins,
        bool _updateAcc
    ) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];

        if (pool.totalSupply > 0 && _updateAcc && rewardRate > 0) {
            uint256 multiplier = block.timestamp.sub(pool.lastRewardTime);
            uint256 rewards = multiplier
                .mul(rewardRate)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            pool.rewardsAmount = pool.rewardsAmount.add(rewards);
            pool.accEulerPerShare = pool.accEulerPerShare.add(
                rewards.mul(1e12).div(pool.totalSupply)
            );
        }
        pool.lastRewardTime = block.timestamp.add(
            _startTimeInMins.mul(1 minutes)
        );
    }

    function totalSupply() external view returns (uint) {
        uint _totalSupply;
        for (uint i = 0; i < poolInfo.length; i++) {
            _totalSupply += poolInfo[i].totalSupply;
        }
        return _totalSupply;
    }

    function availableRewards() public view returns (uint remain, uint insuff) {
        uint pendings;
        for (uint i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            pendings += pool.rewardsAmount;
            if (pool.lastRewardTime >= block.timestamp) continue;
            uint256 multiplier = Math.min(block.timestamp, endTime).sub(
                pool.lastRewardTime
            );
            uint256 reward = multiplier
                .mul(rewardRate)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            pendings += reward;
        }

        uint bal = rewardToken.balanceOf(address(this));
        if (bal < pendings) insuff = pendings - bal;
        else remain = bal - pendings;
    }

    function getPoolCount() external view returns (uint) {
        return poolInfo.length;
    }

    function userCount() external view returns (uint) {
        return users.length();
    }

    function deposit(
        uint256 _pid,
        uint256 _amount
    ) external whenNotPaused nonReentrant updateReward(_pid) updateUserList {
        require(block.timestamp < endTime, "pool already expired");
        require(_amount > 0, "!amount");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint before = lpToken.balanceOf(address(this));
        lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = lpToken.balanceOf(address(this)).sub(before);

        pool.totalSupply += _amount;
        user.amount += _amount;
        user.depositedAt = block.timestamp;
        user.unlockedAt = 0;

        emit Deposit(_pid, msg.sender, _amount);
    }

    function expand(
        uint _from,
        uint _to,
        uint _amount
    )
        external
        whenNotPaused
        nonReentrant
        updateReward(_from)
        updateReward(_to)
    {
        require(block.timestamp < endTime, "pool already expired");
        require(_amount > 0, "!amount");
        PoolInfo storage fromPool = poolInfo[_from];
        PoolInfo storage toPool = poolInfo[_to];
        UserInfo storage fromUser = userInfo[_from][msg.sender];
        UserInfo storage toUser = userInfo[_to][msg.sender];
        require(fromUser.amount >= _amount, "!balance");

        fromPool.totalSupply -= _amount;
        toPool.totalSupply += _amount;

        fromUser.amount -= _amount;

        toUser.amount += _amount;
        toUser.depositedAt = block.timestamp;
        toUser.unlockedAt = 0;
    }

    function withdraw(
        uint256 _pid,
        uint256 _amount
    ) public nonReentrant updateReward(_pid) updateUserList {
        require(_amount > 0, "!amount");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            block.timestamp.sub(user.depositedAt) > pool.lockupDuration,
            "!available to withdraw"
        );
        if (unlockDuration > 0) {
            require(
                user.unlockedAt > 0 &&
                    block.timestamp.sub(user.unlockedAt) > unlockDuration,
                "still locked"
            );
        }
        require(user.amount >= _amount, "!balance");

        user.amount -= _amount;
        pool.totalSupply -= _amount;
        lpToken.safeTransfer(msg.sender, _amount);

        emit Withdraw(_pid, msg.sender, _amount);
    }

    function withdrawAll(uint _pid) external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        withdraw(_pid, user.amount);
    }

    function claim(uint256 _pid) public updateReward(_pid) returns (uint) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 claimedAmount = safeTransferRewards(
            msg.sender,
            user.pendingRewards
        );
        user.pendingRewards = user.pendingRewards.sub(claimedAmount);
        user.claimedAt = block.timestamp;
        pool.rewardsAmount -= claimedAmount;

        emit Claim(_pid, msg.sender, claimedAmount);

        return claimedAmount;
    }

    function claimForAll() external nonReentrant {
        uint claimedAmount = 0;
        for (uint i = 0; i < poolInfo.length; i++) {
            claimedAmount += claim(i);
        }
        if (claimedAmount > 0) claimTimes++;
    }

    function claimable(
        uint256 _pid,
        address _user
    ) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 curAccPerShare = pool.accEulerPerShare;
        if (pool.lastRewardTime <= block.timestamp && pool.totalSupply > 0) {
            uint256 multiplier = Math.min(block.timestamp, endTime).sub(
                pool.lastRewardTime
            );
            uint256 reward = multiplier
                .mul(rewardRate)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            curAccPerShare = pool.accEulerPerShare.add(
                reward.mul(1e12).div(pool.totalSupply)
            );
        }

        return
            user.amount.mul(curAccPerShare).div(1e12).sub(user.rewardDebt).add(
                user.pendingRewards
            );
    }

    function claimableForAll(address _user) external view returns (uint256) {
        uint amount = 0;
        for (uint i = 0; i < poolInfo.length; i++) {
            amount += claimable(i, _user);
        }
        return amount;
    }

    function safeTransferRewards(
        address _user,
        uint _amount
    ) internal returns (uint) {
        uint curBal = rewardToken.balanceOf(address(this));
        require(curBal > 0, "!rewards");

        if (_amount > curBal) _amount = curBal;
        if (_amount > 0) {
            rewardToken.safeTransfer(_user, _amount);
        }

        return _amount;
    }

    function updateAllPools() internal {
        // Update pool infos with old reward rate before setting new one first
        if (rewardRate > 0) {
            for (uint i = 0; i < poolInfo.length; i++) {
                PoolInfo storage pool = poolInfo[i];
                if (pool.lastRewardTime >= block.timestamp) continue;

                if (pool.totalSupply > 0) {
                    uint256 multiplier = block.timestamp.sub(
                        pool.lastRewardTime
                    );
                    uint256 reward = multiplier
                        .mul(rewardRate)
                        .mul(pool.allocPoint)
                        .div(totalAllocPoint);
                    pool.rewardsAmount += reward;
                    pool.accEulerPerShare += reward.mul(1e12).div(
                        pool.totalSupply
                    );
                }
                pool.lastRewardTime = block.timestamp;
            }
        }
    }

    function setRewardRate(uint256 _rewardRate) public onlyFactory {
        require(
            _rewardRate > 0,
            "Rewards per second should be greater than 0!"
        );

        updateAllPools();
        rewardRate = _rewardRate;
    }

    function expandEndTime(uint _mins) external onlyFactory {
        require(_mins > 0, "!period");
        (uint remain, uint insuff) = availableRewards();
        require(insuff == 0, "!availalbe by insufficient rewards");

        updateAllPools();

        if (endTime >= block.timestamp) {
            endTime += _mins.mul(1 minutes);
        } else {
            endTime = block.timestamp + _mins.mul(1 minutes);
        }

        rewardRate = remain.div(endTime.sub(block.timestamp));
    }

    function rescueTokens(address _token) external onlyFactory {
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        if (_balance > 0) {
            IERC20(_token).safeTransfer(msg.sender, _balance);
        }
    }

    function _removeUser(address _user) internal {
        if (users.contains(_user) == true) {
            users.remove(_user);
        }
    }

    function _checkOrAddUser(address _user) internal {
        if (users.contains(_user) == false) {
            users.add(_user);
        }
    }

    function pause() external onlyFactory {
        _pause();
    }

    function unpause() external onlyFactory {
        _unpause();
    }
}