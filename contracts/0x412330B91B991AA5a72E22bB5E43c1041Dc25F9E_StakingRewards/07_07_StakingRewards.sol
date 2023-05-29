pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract StakingRewards is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many stake tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        bool emergencySwitch;
        IERC20 stakeToken;
        IERC20 rewardToken;
        uint256 stakeTokenSupply;
        uint256 startTimestamp;
        uint256 rewardPerSecond;
        uint256 totalReward;
        uint256 leftReward;
        uint256 lastRewardTimestamp;
        uint256 rewardPerShare;
    }

    // All pools.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes stake tokens. pid => user address => info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor() public {}

    // Add a new pool
    function add(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _startTimestamp,
        uint256 _rewardPerSecond,
        uint256 _totalReward
    ) public onlyOwner {
        require(_totalReward > _rewardPerSecond, "total < reward");

        uint256 lastRewardTimestamp = block.timestamp > _startTimestamp ? block.timestamp : _startTimestamp;
        poolInfo.push(
            PoolInfo({
                emergencySwitch: false,
                stakeToken: _stakeToken,
                rewardToken: _rewardToken,
                stakeTokenSupply: 0,
                startTimestamp: _startTimestamp,
                rewardPerSecond: _rewardPerSecond,
                totalReward: _totalReward,
                leftReward: _totalReward,
                lastRewardTimestamp: lastRewardTimestamp,
                rewardPerShare: 0
            })
        );
    }

    function set(uint256 _pid, bool _emergencySwitch) public onlyOwner {
        poolInfo[_pid].emergencySwitch = _emergencySwitch;
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.emergencySwitch) {
            return;
        }
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        if (pool.stakeTokenSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 reward = getPoolReward(
            pool.lastRewardTimestamp,
            block.timestamp,
            pool.rewardPerSecond,
            pool.leftReward
        );

        if (reward > 0) {
            pool.leftReward = pool.leftReward.sub(reward);
            pool.rewardPerShare = pool.rewardPerShare.add(reward.mul(1e12).div(pool.stakeTokenSupply));
        }
        pool.lastRewardTimestamp = block.timestamp;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.emergencySwitch) {
            return;
        }
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.rewardPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeTransferReward(pool.rewardToken, msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.stakeToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.stakeTokenSupply = pool.stakeTokenSupply.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.rewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.emergencySwitch) {
            emergencyWithdraw(_pid);
            return;
        }
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0 && user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);

        require(pool.leftReward == 0, "still locked");

        uint256 pending = user.amount.mul(pool.rewardPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeTransferReward(pool.rewardToken, msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.stakeTokenSupply = pool.stakeTokenSupply.sub(_amount);
            pool.stakeToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.rewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function claimReward(uint256 _pid) public {
        deposit(_pid, 0);
    }

    function safeTransferReward(IERC20 rewardToken, address _to, uint256 _amount) internal {
        uint256 bal = rewardToken.balanceOf(address(this));
        require(bal >= _amount, "balance not enough");
        rewardToken.safeTransfer(_to, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 willWithdrawAmount = user.amount;
        require(willWithdrawAmount > 0, "no stake amount");

        pool.stakeTokenSupply = pool.stakeTokenSupply.sub(willWithdrawAmount);
        user.amount = 0;
        user.rewardDebt = 0;

        pool.stakeToken.safeTransfer(address(msg.sender), willWithdrawAmount);
        emit EmergencyWithdraw(msg.sender, _pid, willWithdrawAmount);
    }

    function getPoolReward(
        uint256 _from,
        uint256 _to,
        uint256 _rewardPerSecond,
        uint256 _leftReward
    ) public pure returns (uint) {
        uint256 amount = _to.sub(_from).mul(_rewardPerSecond);
        return _leftReward < amount ? _leftReward : amount;
    }

    function getUserClaimableReward(uint _pid, address _user) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 rewardPerShare = pool.rewardPerShare;
        if (block.timestamp > pool.lastRewardTimestamp && pool.stakeTokenSupply > 0) {
            uint256 reward = getPoolReward(
                pool.lastRewardTimestamp,
                block.timestamp,
                pool.rewardPerSecond,
                pool.leftReward
            );
            rewardPerShare = rewardPerShare.add(reward.mul(1e12).div(pool.stakeTokenSupply));
        }
        return user.amount.mul(rewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
}