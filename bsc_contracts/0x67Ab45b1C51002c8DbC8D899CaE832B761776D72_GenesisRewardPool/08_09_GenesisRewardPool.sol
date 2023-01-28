// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../owner/Operator.sol";

contract GenesisRewardPool is Operator{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. CRS to distribute.
        uint256 lastRewardTime; // Last time that CRS distribution occurs.
        uint256 accCRSPerShare; // Accumulated CRS per share, times 1e18. See below.
        bool isStarted; // if lastRewardBlock has passed
        uint256 depositFee; // deposit fee
    }

    IERC20 public crystal;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // Fee collector address
    address public feeCollector;

    // The time when CRS mining starts.
    uint256 public poolStartTime;

    // The time when CRS mining ends.
    uint256 public poolEndTime;

    // MAINNET
    uint256 public crystalPerSecond = 0.0231481 ether; // 6000 CRS / (3 days * 24h * 60min * 60s)
    uint256 public runningTime = 3 days; // 3 days
    uint256 public constant TOTAL_REWARDS = 6000 ether;
    // END MAINNET

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    constructor(address _crystal, uint256 _poolStartTime, address _feeCollector) {
        require(block.timestamp < _poolStartTime, "late");
        require(_crystal != address(0), "Crystal should be non-zero address");
        require(_feeCollector != address(0), "Fee Collector should be non-zero address");

        crystal = IERC20(_crystal);
        feeCollector = _feeCollector;
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "This pool already exist");
        }
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        uint256 _depositFee,
        bool _withUpdate,
        uint256 _lastRewardTime
    ) public onlyOperator {
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
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
        poolInfo.push(
            PoolInfo({
                token: _token, 
                allocPoint: _allocPoint, 
                depositFee: _depositFee,
                lastRewardTime: _lastRewardTime, 
                accCRSPerShare: 0, 
                isStarted: _isStarted}));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's CRS allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFee) public onlyOperator {
        require(_depositFee < 10000, "deposit fee should be less than 10000");

        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
        }
        pool.allocPoint = _allocPoint;
        pool.depositFee = _depositFee;
    }

    // Set Fee Collector address
    function setFeeCollector(address _feeCollector) public onlyOperator {
        require(_feeCollector != address(0), "Fee collector should be non-zero address");
        feeCollector = _feeCollector;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(crystalPerSecond);
            return poolEndTime.sub(_fromTime).mul(crystalPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(crystalPerSecond);
            return _toTime.sub(_fromTime).mul(crystalPerSecond);
        }
    }

    // View function to see pending CRS on frontend.
    function pendingCRS(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCRSPerShare = pool.accCRSPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _crystalReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accCRSPerShare = accCRSPerShare.add(_crystalReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accCRSPerShare).div(1e18).sub(user.rewardDebt);
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
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _crystalReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accCRSPerShare = pool.accCRSPerShare.add(_crystalReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accCRSPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeCRSTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            if (pool.depositFee > 0) {
                uint256 feeAmount = _amount.mul(pool.depositFee).div(10000);
                pool.token.safeTransferFrom(_sender, feeCollector, feeAmount);
                pool.token.safeTransferFrom(_sender, address(this), _amount.sub(feeAmount));
                user.amount = user.amount.add(_amount.sub(feeAmount));
            } else {
                pool.token.safeTransferFrom(_sender, address(this), _amount);
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accCRSPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accCRSPerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeCRSTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCRSPerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe CRS transfer function, just in case if rounding error causes pool to not have enough CRSs.
    function safeCRSTransfer(address _to, uint256 _amount) internal {
        uint256 _crystalBalance = crystal.balanceOf(address(this));
        if (_crystalBalance > 0) {
            if (_amount > _crystalBalance) {
                crystal.safeTransfer(_to, _crystalBalance);
            } else {
                crystal.safeTransfer(_to, _amount);
            }
        }
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        if (block.timestamp < poolEndTime + 90 days) {
            // do not allow to drain core token (CRS or lps) if less than 90 days after pool ends
            require(_token != crystal, "Shouldn't drain CRS if less than 90 days after pool ends");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "Shouldn't drain staking token & LPs if less than 90 days after pool ends");
            }
        }
        _token.safeTransfer(_to, _amount);
    }
}