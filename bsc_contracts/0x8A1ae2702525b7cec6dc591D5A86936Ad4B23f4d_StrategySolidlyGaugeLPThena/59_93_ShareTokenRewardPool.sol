// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./lib/SafeMath.sol";
import "./owner/Operator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ShareTokenRewardPool is Operator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 lastRewardTime;
        uint256[18] rewardDebt;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ShareToken to distribute per block.
        uint256 lastRewardTime; // Last time that ShareToken distribution occurs.
        uint256[18] accRewardTokenPerShare; // Accumulated ShareToken per share, times 1e18. See below.
        bool isStarted; // if lastRewardTime has passed
        uint256 depositFeePercent;
    }

    struct RewardInfo {
        uint256 rewardForDao;
        uint256 rewardForDev;
        uint256 rewardForUser;
        uint256 rewardPerSecondForDao;
        uint256 rewardPerSecondForDev;
        uint256 rewardPerSecondForUser;
        uint256 startTime;
    }

    IERC20 public immutable shareToken;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint;

    uint256 public immutable poolStartTime;
    uint256 public immutable poolEndTime;

    uint256 public constant runningTimeMonth = 18; // 18 months

    RewardInfo[18] public rewardInfos;
    uint256 public lastDaoRewardTime;
    uint256 public lastDevRewardTime;
    address public immutable devWallet;
	address public immutable daoWallet;
    address public immutable polWallet;

    uint256 constant public MONTH = 30 * 24 * 60 * 60;
    uint256 constant public firstMonthReward = 3666 ether;
    uint256 public totalUserReward = 0;
    uint256 public totalDevReward = 0;
    uint256 constant public devPercent = 1000; // 10%
    uint256 public totalDaoReward = 0;
    uint256 constant public daoPercent = 1000; // 10%
    uint256 constant rewardDecreaseEachMonthPercent = 2000; // 20%

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event SetDepositFeePercent(uint256 oldValue, uint256 newValue);

    constructor(
        address _token,
        address _daoWallet,
        address _devWallet,
        address _polWallet,
        uint256 _poolStartTime
    ) {
        require(block.timestamp < _poolStartTime, "late");
        require(_token != address(0), "!_token");
        require(_daoWallet != address(0), "!_daoWallet");
        require(_devWallet != address(0), "!_devWallet");
        require(_polWallet != address(0), "!_polWallet");

        shareToken = IERC20(_token);

        daoWallet = _daoWallet;
        devWallet = _devWallet; 
        polWallet = _polWallet;

        totalAllocPoint = 0;
        poolStartTime = _poolStartTime;

        lastDaoRewardTime = poolStartTime;
        lastDevRewardTime = poolStartTime;
        uint256 runningTime = runningTimeMonth * MONTH;
        poolEndTime = poolStartTime + runningTime;

        uint256 devRewardFirstMonth = firstMonthReward * devPercent / 10000;
        uint256 daoRewardFirstMonth = firstMonthReward * daoPercent / 10000;
        uint256 userRewardFirstMonth = firstMonthReward - devRewardFirstMonth - daoRewardFirstMonth;
        uint256 startTime = poolStartTime;
        for (uint256 i = 0; i < runningTimeMonth; ++i) {
            rewardInfos[i].rewardForDev = devRewardFirstMonth;
            rewardInfos[i].rewardForDao = daoRewardFirstMonth;
            rewardInfos[i].rewardForUser = userRewardFirstMonth;
            rewardInfos[i].startTime = startTime;

            rewardInfos[i].rewardPerSecondForDev = devRewardFirstMonth / MONTH;
            rewardInfos[i].rewardPerSecondForDao = daoRewardFirstMonth / MONTH;
            rewardInfos[i].rewardPerSecondForUser = userRewardFirstMonth / MONTH;

            devRewardFirstMonth = devRewardFirstMonth - (devRewardFirstMonth * rewardDecreaseEachMonthPercent / 10000);
            daoRewardFirstMonth = daoRewardFirstMonth - (daoRewardFirstMonth * rewardDecreaseEachMonthPercent / 10000);
            userRewardFirstMonth = userRewardFirstMonth - (userRewardFirstMonth * rewardDecreaseEachMonthPercent / 10000);
            startTime = startTime + MONTH;

            totalDevReward = totalDevReward + rewardInfos[i].rewardForDev;
            totalDaoReward = totalDaoReward + rewardInfos[i].rewardForDao;
            totalUserReward = totalUserReward + rewardInfos[i].rewardForUser;
        }
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "ShareTokenRewardPool: existing pool?");
        }
    }

    // Add a new pool. Can only be called by the Operator.
    function add(
        uint256 _allocPoint,
        address _token,
        uint256 _depositFee,
        uint256 _lastRewardTime
    ) external onlyOperator {
        require(_token != address(0), "!_token");
        require(_depositFee <= 100, 'Max percent is 1%');
        checkPoolDuplicate(IERC20(_token));
        massUpdatePools();
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = poolStartTime;
            } else {
                if (_lastRewardTime < poolStartTime) {
                    _lastRewardTime = poolStartTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted = (_lastRewardTime <= poolStartTime) || (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : IERC20(_token),
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accRewardTokenPerShare : [uint256(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            isStarted : _isStarted,
            depositFeePercent: _depositFee
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's ShareToken allocation point. Can only be called by the Operator.
    function set(uint256 _pid, uint256 _allocPoint) external onlyOperator {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
    }

    function setDepositFeePercent(uint256 _pid, uint256 _value) external onlyOperator {
        require(_value <= 100, 'Max percent is 1%');
        PoolInfo storage pool = poolInfo[_pid];
        emit SetDepositFeePercent(pool.depositFeePercent, _value);
        pool.depositFeePercent = _value;
    }

    // View function to see pending on frontend.
    function pending(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        uint256 daoReward = pendingDao(_user, lastDaoRewardTime, block.timestamp);
        uint256 devReward = pendingDev(_user, lastDevRewardTime, block.timestamp);
        uint256 userReward = pendingUser(_pid, _user, pool.lastRewardTime, block.timestamp);
        return userReward.add(daoReward).add(devReward);
    }

    function pendingUser(uint256 _pid, address _user, uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime > _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) _fromTime = poolStartTime;
            _toTime = poolEndTime;
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) _fromTime = poolStartTime;
        }

        uint256 reward = getUserReward(_pid, _user, _fromTime, _toTime);
        return reward;
    }

    function pendingDao(address _user, uint256 _fromTime, uint256 _toTime) internal view returns (uint256) {
        if (isDao(_user)) {
            if (_fromTime >= _toTime) return 0;
            if (_toTime >= poolEndTime) {
                if (_fromTime >= poolEndTime) return 0;
                if (_fromTime <= poolStartTime) _fromTime = poolStartTime;
                _toTime = poolEndTime;
                uint256 reward = getDaoReward(_fromTime, _toTime);
                return reward;
            } else {
                if (_toTime <= poolStartTime) return 0;
                if (_fromTime <= poolStartTime) _fromTime = poolStartTime;

                uint256 reward = getDaoReward(_fromTime, _toTime);
                return reward;
            }
        }

        return 0;
    }

    function pendingDev(address _user, uint256 _fromTime, uint256 _toTime) internal view returns (uint256) {
        if (isDev(_user)) {
            if (_fromTime >= _toTime) return 0;
            if (_toTime >= poolEndTime) {
                if (_fromTime >= poolEndTime) return 0;
                if (_fromTime <= poolStartTime) _fromTime = poolStartTime;
                _toTime = poolEndTime;
                uint256 reward = getDevReward(_fromTime, _toTime);
                return reward;
            } else {
                if (_toTime <= poolStartTime) return 0;
                if (_fromTime <= poolStartTime) _fromTime = poolStartTime;

                uint256 reward = getDevReward(_fromTime, _toTime);
                return reward;
            }
        }

        return 0;
    }

    function getDaoReward(uint256 _fromTime, uint256 _toTime) internal view returns (uint256) {
        uint256 fromMonth = getMonthFrom(_fromTime);
        uint256 toMonth = getMonthFrom(_toTime);
        uint256 reward = 0;
        for (uint256 i = fromMonth; i <= toMonth; ++i) {
            uint256 timeFrom = _fromTime;
            uint256 timeTo = poolEndTime;
            if (i < runningTimeMonth - 1) {
                timeTo = rewardInfos[i + 1].startTime > _toTime ? _toTime : rewardInfos[i + 1].startTime;
            }
            reward = reward + timeTo.sub(timeFrom).mul(rewardInfos[i].rewardPerSecondForDao);
            _fromTime = timeTo;
        } 
        
        return reward;
    }

    function getDevReward(uint256 _fromTime, uint256 _toTime) internal view returns (uint256) {
        uint256 fromMonth = getMonthFrom(_fromTime);
        uint256 toMonth = getMonthFrom(_toTime);
        uint256 reward = 0;
        for (uint256 i = fromMonth; i <= toMonth; ++i) {
            uint256 timeFrom = _fromTime;
            uint256 timeTo = poolEndTime;
            if (i < runningTimeMonth - 1) {
                timeTo = rewardInfos[i + 1].startTime > _toTime ? _toTime : rewardInfos[i + 1].startTime;
            }
            reward = reward + timeTo.sub(timeFrom).mul(rewardInfos[i].rewardPerSecondForDev);
            _fromTime = timeTo;
        } 
        
        return reward;
    }

    function getUserReward(uint256 _pid, address _user, uint256 _fromTime, uint256 _toTime) internal view returns (uint256) {
        UserInfo memory user = userInfo[_pid][_user];
        PoolInfo memory pool = poolInfo[_pid];
        uint256 reward = 0;
        uint256 userAmount = user.amount;
        uint256 lastUserRewardMonth = getMonthFrom(user.lastRewardTime);
        uint256 fromMonth = getMonthFrom(_fromTime);
        uint256 toMonth = getMonthFrom(_toTime);
        if (fromMonth > lastUserRewardMonth) {
            for (uint256 i = lastUserRewardMonth; i < fromMonth; ++i) {
                reward = reward + userAmount.mul( pool.accRewardTokenPerShare[i]).div(1e18).sub(user.rewardDebt[i]);
            }
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        for (uint256 i = fromMonth; i <= toMonth; ++i) {
            uint256 timeFrom = _fromTime;
            uint256 timeTo = poolEndTime;
            if (i < runningTimeMonth - 1) {
                timeTo = rewardInfos[i + 1].startTime > _toTime ? _toTime : rewardInfos[i + 1].startTime;
            }
            uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare[i];
            if (tokenSupply > 0) {
                uint256 _generatedReward = timeTo.sub(timeFrom).mul(rewardInfos[i].rewardPerSecondForUser);
                uint256 _shareTokenReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
                accRewardTokenPerShare = accRewardTokenPerShare.add(_shareTokenReward.mul(1e18).div(tokenSupply));
            }
            reward = reward + userAmount.mul(accRewardTokenPerShare).div(1e18).sub(user.rewardDebt[i]);
            _fromTime = timeTo;
        } 
        return reward;
    }

    function getUserRewardToClaim(uint256 _pid, address _user, uint256 _fromTime, uint256 _toTime) internal view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 reward = 0;
        uint256 userAmount = user.amount;
        uint256 fromMonth = getMonthFrom(_fromTime);
        uint256 toMonth = getMonthFrom(_toTime);

        for (uint256 i = fromMonth; i <= toMonth; ++i) {
            uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare[i];
            reward = reward + userAmount.mul(accRewardTokenPerShare).div(1e18).sub(user.rewardDebt[i]);
        } 
        
        return reward;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public onlyOperator {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        
        if (totalAllocPoint > 0) {
            uint256 _fromTime = pool.lastRewardTime > poolEndTime ? poolEndTime : pool.lastRewardTime;
            uint256 _toTime = block.timestamp;
            uint256 fromMonth = getMonthFrom(_fromTime);
            uint256 toMonth = getMonthFrom(_toTime);
            for (uint256 i = fromMonth; i <= toMonth; ++i) {
                uint256 timeFrom = _fromTime;
                uint256 timeTo = poolEndTime;
                if (i < runningTimeMonth - 1) {
                    timeTo = rewardInfos[i + 1].startTime > _toTime ? _toTime : rewardInfos[i + 1].startTime;
                }

                uint256 _generatedReward = timeTo.sub(timeFrom).mul(rewardInfos[i].rewardPerSecondForUser);
                uint256 _shareTokenReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
                pool.accRewardTokenPerShare[i] = pool.accRewardTokenPerShare[i].add(_shareTokenReward.mul(1e18).div(tokenSupply));

                _fromTime = timeTo;
            }
        }

        pool.lastRewardTime = block.timestamp;
    }

    // Deposit tokens.
    function deposit(uint256 _pid, uint256 _amount) external {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        uint256 lastRewardTime = pool.lastRewardTime;
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = getUserRewardToClaim(_pid, _sender, user.lastRewardTime, block.timestamp);
            if (_pending > 0) {
                safeShareTokenTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        user.lastRewardTime = block.timestamp;
        if (_amount > 0) {
            if (pool.depositFeePercent > 0) {
                uint256 feeAmount = _amount.mul(pool.depositFeePercent).div(10000);
                pool.token.safeTransferFrom(_sender, polWallet, feeAmount);
                _amount = _amount.sub(feeAmount);
            }

            pool.token.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
        }

        uint256 fromMonth = getMonthFrom(lastRewardTime);
        uint256 toMonth = getMonth();
        for (uint256 i = fromMonth; i <= toMonth; ++i) {
            user.rewardDebt[i] = user.amount.mul(pool.accRewardTokenPerShare[i]).div(1e18);
        }
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw tokens.
    function withdraw(uint256 _pid, uint256 _amount) external {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        uint256 lastRewardTime = pool.lastRewardTime;
        updatePool(_pid);
        uint256 _pending = getUserRewardToClaim(_pid, _sender, user.lastRewardTime, block.timestamp);
        user.lastRewardTime = block.timestamp;
        uint256 _daoReward = pendingDao(_sender, lastDaoRewardTime, block.timestamp);
        uint256 _devReward = pendingDev(_sender, lastDevRewardTime, block.timestamp);
        uint256 _reward = 0;

        if (_daoReward > 0) {
            _reward = _reward.add(_daoReward);
            lastDaoRewardTime = block.timestamp;
        }

        if (_devReward > 0) {
            _reward = _reward.add(_devReward);
            lastDevRewardTime = block.timestamp;
        }

        if (_pending > 0) {
            _reward = _reward.add(_pending);
        }

        if (_reward > 0) {
            safeShareTokenTransfer(_sender, _reward);
            emit RewardPaid(_sender, _pending);
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }

        uint256 fromMonth = getMonthFrom(lastRewardTime);
        uint256 toMonth = getMonth();
        for (uint256 i = fromMonth; i <= toMonth; ++i) {
            user.rewardDebt[i] = user.amount.mul(pool.accRewardTokenPerShare[i]).div(1e18);
        }

        emit Withdraw(_sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        for (uint256 i = 0; i < 18; ++i) {
            user.rewardDebt[i] = 0;
        }
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe ShareToken transfer function, just in case if rounding error causes pool to not have enough ShareToken.
    function safeShareTokenTransfer(address _to, uint256 _amount) internal {
        uint256 _shareTokenBalance = shareToken.balanceOf(address(this));
        if (_shareTokenBalance > 0) {
            if (_amount > _shareTokenBalance) {
                shareToken.safeTransfer(_to, _shareTokenBalance);
            } else {
                shareToken.safeTransfer(_to, _amount);
            }
        }
    }

    function isDev(address _address) public view returns (bool) {
		return _address == devWallet;
	}

	function isDao(address _address) public view returns (bool) {
		return _address == daoWallet;
	}

    function getMonth() public view returns (uint256) {
        if (block.timestamp < poolStartTime) return 0;
        uint256 month = (block.timestamp - poolStartTime) / MONTH;
        return month > runningTimeMonth - 1 ? runningTimeMonth - 1 : month;
    }

    function getMonthFrom(uint256 _time) public view returns (uint256) {
        if (_time < poolStartTime) return 0;
        uint256 month = (_time - poolStartTime) / MONTH;
        return month > runningTimeMonth - 1 ? runningTimeMonth - 1 : month;
    }
}