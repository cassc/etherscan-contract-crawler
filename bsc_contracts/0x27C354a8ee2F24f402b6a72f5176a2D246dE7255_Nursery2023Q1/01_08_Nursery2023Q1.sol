// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./owner/Operator.sol";

// Note that this pool has no minter key of LIFE (rewards).
// Instead, rewards will be sent to this pool at the beginning.
contract Nursery2023Q1 is Operator {
    using SafeERC20 for IERC20;


    /// User-specific information.
    struct UserInfo {
        /// How many tokens the user provided.
        uint256 amount;
        /// How many unclaimed rewards does the user have pending.
        uint256 rewardDebt;
    }

    /// Pool-specific information.
    struct PoolInfo {
        /// Address of the token staked in the pool.
        IERC20 token;
        /// Allocation points assigned to the pool.
        /// @dev Rewards are distributed in the pool according to formula: (allocPoint / totalAllocPoint) * lifePerSecond
        uint256 allocPoint;
        /// Last time the rewards distribution was calculated.
        uint256 lastRewardTime;
        /// Accumulated LIFE per share.
        uint256 accLifePerShare;
        /// Deposit fee in %, where 100 == 1%.
        uint16 depositFee;
        /// Is the pool rewards emission started.
        bool isStarted;
    }

    /// Reward token.
    IERC20 public life;

    /// Address where the deposit fees are transferred.
    address public feeCollector;

    /// Information about each pool.
    PoolInfo[] public poolInfo;

    /// Information about each user in each pool.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    /// The time when LIFE emissions start.
    uint256 public poolStartTime;

    /// The time when LIFE emissions end.
    uint256 public poolEndTime;

    /// Amount of LIFE emitted each second.
    uint256 public lifePerSecond;
    /// Running time of emissions (in seconds).
    uint256 public runningTime;
    /// Total amount of tokens to be emitted.
    uint256 public totalRewards;

    /* Events */

    event AddPool(address indexed user, uint256 indexed pid, uint256 allocPoint, uint256 totalAllocPoint, uint16 depositFee);
    event ModifyPool(address indexed user, uint256 indexed pid, uint256 allocPoint, uint256 totalAllocPoint, uint16 depositFee);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 depositFee);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event UpdateFeeCollector(address indexed user, address feeCollector);
    event RecoverUnsupported(address indexed user, address token, uint256 amount, address targetAddress);


    /// Default constructor.
    /// @param _lifeAddress Address of LIFE token.
    /// @param _poolStartTime Emissions start time.
    /// @param _runningTime Running time of emissions (in seconds).
    /// @param _totalRewards Total amount of tokens to be emitted.
    /// @param _feeCollector Address where the deposit fees are transferred.
    constructor(
        address _lifeAddress,
        uint256 _poolStartTime,
        uint256 _runningTime,
        uint256 _totalRewards,
        address _feeCollector
    ) {
        require(block.timestamp < _poolStartTime, "late");
        require(_feeCollector != address(0), "Address cannot be 0");
        require(_runningTime >= 1 days, "Running time has to be at least 1 day");

        if (_lifeAddress != address(0)) life = IERC20(_lifeAddress);

        poolStartTime = _poolStartTime;
        runningTime = _runningTime;
        poolEndTime = poolStartTime + runningTime;

        totalRewards = _totalRewards;
        lifePerSecond = totalRewards / runningTime;

        feeCollector = _feeCollector;
    }

    /// Check if a pool already exists for specified token.
    /// @param _token Address of token to check for existing pools
    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "LifeGenesisRewardPool: existing pool?");
        }
    }

    /// Add a new pool.
    /// @param _allocPoint Allocations points assigned to the pool
    /// @param _token Address of token to be staked in the pool
    /// @param _depositFee Deposit fee in % (where 100 == 1%)
    /// @param _withUpdate Whether to trigger update of all existing pools
    /// @param _lastRewardTime Start time of the emissions from the pool
    /// @dev Can only be called by the Operator.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        uint16 _depositFee,
        bool _withUpdate,
        uint256 _lastRewardTime
    ) public onlyOperator {
        _token.balanceOf(address(this));    // guard to revert calls that try to add non-IERC20 addresses
        require(_depositFee <= 4000, "Deposit fee cannot be higher than 40%");
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
        bool _isStarted =
        (_lastRewardTime <= poolStartTime) ||
        (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : _token,
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accLifePerShare : 0,
            depositFee: _depositFee,
            isStarted : _isStarted
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint + _allocPoint;
        }

        emit AddPool(msg.sender, poolInfo.length - 1, _allocPoint, totalAllocPoint, _depositFee);
    }

    /// Update the given pool's parameters.
    /// @param _pid Id of an existing pool
    /// @param _allocPoint New allocations points assigned to the pool
    /// @param _depositFee New deposit fee assigned to the pool
    /// @dev Can only be called by the Operator.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFee) public onlyOperator {
        require(_depositFee <= 4000, "Deposit fee cannot be higher than 40%");
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = (totalAllocPoint - pool.allocPoint) + _allocPoint;
        }
        pool.allocPoint = _allocPoint;
        pool.depositFee = _depositFee;

        emit ModifyPool(msg.sender, _pid, _allocPoint, totalAllocPoint, _depositFee);
    }

    /// Return amount of accumulated rewards over the given time, according to the life per second emission.
    /// @param _fromTime Time from which the generated rewards should be calculated
    /// @param _toTime Time to which the generated rewards should be calculated
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return (poolEndTime - poolStartTime) * lifePerSecond;
            return (poolEndTime - _fromTime) * lifePerSecond;
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return (_toTime - poolStartTime) * lifePerSecond;
            return (_toTime - _fromTime) * lifePerSecond;
        }
    }

    /// Estimate pending rewards for specific user.
    /// @param _pid Id of an existing pool
    /// @param _user Address of a user for which the pending rewards should be calculated
    /// @return Amount of pending rewards for specific user
    /// @dev To be used in UI
    function pendingShare(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accLifePerShare = pool.accLifePerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _lifeReward = (_generatedReward * pool.allocPoint) / totalAllocPoint;
            accLifePerShare = accLifePerShare + ((_lifeReward * 1e18) / tokenSupply);
        }
        return ((user.amount * accLifePerShare) / 1e18) - user.rewardDebt;
    }

    /// Update reward variables for all pools.
    /// @dev Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// Update reward variables of the given pool to be up-to-date.
    /// @param _pid Id of the pool to be updated
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
            totalAllocPoint = totalAllocPoint + pool.allocPoint;
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _lifeReward = (_generatedReward * pool.allocPoint) / totalAllocPoint;
            pool.accLifePerShare = pool.accLifePerShare + ((_lifeReward * 1e18) / tokenSupply);
        }
        pool.lastRewardTime = block.timestamp;
    }

    /// Deposit tokens in a pool.
    /// @param _pid Id of the chosen pool
    /// @param _amount Amount of tokens to be staked in the pool
    function deposit(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = ((user.amount * pool.accLifePerShare) / 1e18) - user.rewardDebt;
            if (_pending > 0) {
                safeLifeTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            if(pool.depositFee > 0) {
                uint256 depositFeeAmount = (_amount * pool.depositFee) / 10000;
                pool.token.safeTransferFrom(_sender, feeCollector, depositFeeAmount);
                pool.token.safeTransferFrom(_sender, address(this), _amount - depositFeeAmount);
                user.amount = user.amount + (_amount - depositFeeAmount);
            } else {
                pool.token.safeTransferFrom(_sender, address(this), _amount);
                user.amount = user.amount + _amount;
            }
        }
        user.rewardDebt = (user.amount * pool.accLifePerShare) / 1e18;
        emit Deposit(_sender, _pid, _amount, pool.depositFee);
    }

    /// Withdraw tokens from a pool.
    /// @param _pid Id of the chosen pool
    /// @param _amount Amount of tokens to be withdrawn from the pool
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = ((user.amount * pool.accLifePerShare) / 1e18) - user.rewardDebt;
        if (_pending > 0) {
            safeLifeTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = (user.amount * pool.accLifePerShare) / 1e18;
        emit Withdraw(_sender, _pid, _amount);
    }

    /// Withdraw tokens from a pool without rewards. ONLY IN CASE OF EMERGENCY.
    /// @param _pid Id of the chosen pool
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    /// Safe LIFE transfer function.
    /// @param _to Recipient address of the transfer
    /// @param _amount Amount of tokens to be transferred
    /// @dev Used just in case if rounding error causes pool to not have enough LIFE.
    function safeLifeTransfer(address _to, uint256 _amount) internal {
        uint256 _lifeBal = life.balanceOf(address(this));
        if (_lifeBal > 0) {
            if (_amount > _lifeBal) {
                life.safeTransfer(_to, _lifeBal);
            } else {
                life.safeTransfer(_to, _amount);
            }
        }
    }

    /// Set a new deposit fees collector address.
    /// @param _feeCollector A new deposit fee collector address
    /// @dev Can only be called by the Operator
    function setFeeCollector(address _feeCollector) external onlyOperator {
        require(_feeCollector != address(0), "Address cannot be 0");
        feeCollector = _feeCollector;
        emit UpdateFeeCollector(msg.sender, address(_feeCollector));
    }

    /// Transferred tokens sent to the contract by mistake.
    /// @param _token Address of token to be transferred (cannot be staking nor the reward token)
    /// @param _amount Amount of tokens to be transferred
    /// @param _to Recipient address of the transfer
    /// @dev Can only be called by the Operator
    function governanceRecoverUnsupported(IERC20 _token, uint256 _amount, address _to) external onlyOperator {
        if (block.timestamp < poolEndTime + 1 days) {
            // do not allow to drain core token (LIFE or lps) if less than 1 day after pool ends
            require(_token != life, "LIFE");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "pool.token");
            }
        }
        _token.safeTransfer(_to, _amount);
        emit RecoverUnsupported(msg.sender, address(_token), _amount, _to);
    }
}