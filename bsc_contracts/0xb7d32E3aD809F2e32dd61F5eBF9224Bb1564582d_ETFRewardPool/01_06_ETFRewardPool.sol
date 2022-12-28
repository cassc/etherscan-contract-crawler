// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ETFRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 token;
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accETFSharePerShare;
        bool isStarted;
    }

    IERC20 public etf;
    address public operator;
    uint256 public totalAllocPoint = 0;
    uint256 public poolStartTime;
    uint256 public poolEndTime;
    uint256 public sharesPerSecond;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    function pendingShare(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accETFSharePerShare = pool.accETFSharePerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _etfReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accETFSharePerShare = accETFSharePerShare.add(_etfReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accETFSharePerShare).div(1e18).sub(user.rewardDebt);
    }

    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(sharesPerSecond);
            return poolEndTime.sub(_fromTime).mul(sharesPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(sharesPerSecond);
            return _toTime.sub(_fromTime).mul(sharesPerSecond);
        }
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    constructor(
        address _etf,
        uint256 _poolStartTime,
        uint256 _poolEndTime,
        uint256 _sharesPerSecond
    ) {
        require(_poolStartTime > block.timestamp, "ETFRewardPool: Start time lte current timestamp");
        require(_poolEndTime > _poolStartTime, "ETFRewardPool: End time lte start time");
        require(_etf != address(0), "ETFRewardPool: ETF is zero address");
        etf = IERC20(_etf);
        poolStartTime = _poolStartTime;
        poolEndTime = _poolEndTime;
        sharesPerSecond = _sharesPerSecond;
        operator = msg.sender;
    }

    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime
    ) external onlyOperator {
        checkPoolDuplicate(_token);
        if (_withUpdate) massUpdatePools();
        if (block.timestamp < poolStartTime) {
            if (_lastRewardTime == 0) _lastRewardTime = poolStartTime;
            else if (_lastRewardTime < poolStartTime) _lastRewardTime = poolStartTime;
        } else {
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) _lastRewardTime = block.timestamp;
        }
        bool _isStarted = (_lastRewardTime <= poolStartTime) || (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : _token,
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accETFSharePerShare : 0,
            isStarted : _isStarted
            }));
        if (_isStarted) totalAllocPoint = totalAllocPoint.add(_allocPoint);
    }

    function deposit(uint256 _pid, uint256 _amount) external {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accETFSharePerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeETFShareTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accETFSharePerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyOperator {
        if (block.timestamp < poolEndTime + 90 days) {
            require(_token != etf, "ETFRewardPool: Recover token eq ETF");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "ETFRewardPool: Recover token eq pool token");
            }
        }
        _token.safeTransfer(to, amount);
    }

    function set(uint256 _pid, uint256 _allocPoint) external onlyOperator {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
        pool.allocPoint = _allocPoint;
    }

    function setOperator(address _operator) external onlyOperator {
        require(_operator != address(0), "ETFRewardPool: Operator is zero address");
        operator = _operator;
    }

    function setSharesPerSecond(uint256 _sharesPerSecond) external onlyOperator {
        sharesPerSecond = _sharesPerSecond;
    }

    function setPoolEndTime(uint256 _poolEndTime) external onlyOperator {
        require(
            _poolEndTime >= block.timestamp && _poolEndTime > poolStartTime,
            "ETFRewardPool: End time lt current timestamp or start time"
        );
        poolEndTime = _poolEndTime;
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "ETFRewardPool: Amount gt available");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accETFSharePerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeETFShareTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accETFSharePerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) updatePool(pid);
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) return;
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
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _etfReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accETFSharePerShare = pool.accETFSharePerShare.add(_etfReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    function checkPoolDuplicate(IERC20 _token) private view {
        uint256 len = poolInfo.length;
        for (uint256 pid = 0; pid < len; ++pid) require(poolInfo[pid].token != _token, "ETFRewardPool: Existing pool");
    }

    function safeETFShareTransfer(address _to, uint256 _amount) private {
        uint256 _etfBal = etf.balanceOf(address(this));
        if (_etfBal > 0) {
            if (_amount > _etfBal) etf.safeTransfer(_to, _etfBal);
            else etf.safeTransfer(_to, _amount);
        }
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "ETFRewardPool: Caller is not operator");
        _;
    }
}