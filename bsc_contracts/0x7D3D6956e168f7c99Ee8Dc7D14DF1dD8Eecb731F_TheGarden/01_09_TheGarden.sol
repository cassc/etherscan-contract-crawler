// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./owner/Operator.sol";
import "./interfaces/IERC20Mintable.sol";


contract TheGarden is Operator {
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
        /// @dev Rewards are distributed in the pool according to formula: (allocPoint / totalAllocPoint) * rewardTokenPerSecond
        uint256 allocPoint;
        /// Last time the rewards distribution was calculated.
        uint256 lastRewardTime;
        /// Accumulated reward token per share. Its sum of all rewardTokens per share amounts, increased by new value on every update
        uint256 accRewardTokenPerShare;
        /// Deposit fee in %, where 100 == 1%.
        uint16 depositFee;
        /// Is the pool rewards emission started.
        bool isStarted;

    }

    /// Reward token.
    IERC20 public rewardToken;

    /// Address where the deposit fees are transferred.
    address public feeCollector;

    /// Information about each pool.
    PoolInfo[] public poolInfo;

    /// Information about each user in each pool.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    /// The time when reward token emissions start.
    uint256 public poolStartTime;

    /// Reward token distribution per second
    uint256 public rewardTokensPerSecond;

    /* Events */

    event AddPool(
        address indexed user,
        uint256 indexed pid,
        uint256 allocPoint,
        uint256 totalAllocPoint,
        uint16 depositFee
    );
    event ModifyPool(
        address indexed user,
        uint256 indexed pid,
        uint256 allocPoint,
        uint256 totalAllocPoint,
        uint16 depositFee
    );
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 depositFee);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event UpdateFeeCollector(address indexed user, address feeCollector);
    event SetRewardTokensPerSecond(address indexed user, uint256 amount);
    event RecoverUnsupported(address indexed user, address token, uint256 amount, address targetAddress);

    /// Default constructor.
    /// @param _rewardToken Address of reward token
    /// @param _poolStartTime Emissions start time
    /// @param _feeCollector Address where the deposit fees are transferred.
    constructor(
        address _rewardToken,
        uint256 _poolStartTime,
        address _feeCollector
    ) {
        require(block.timestamp < _poolStartTime, "Start time too early");
        require(_feeCollector != address(0), "Fee collector address cannot be 0 address");
        require(_rewardToken != address(0), "Reward token address cannot be 0");
        rewardToken = IERC20(_rewardToken);
        poolStartTime = _poolStartTime;
        feeCollector = _feeCollector;
    }

    /// Estimate pending rewards for specific user.
    /// @param _pid Id of an existing pool
    /// @param _user Address of a user for which the pending rewards should be calculated
    /// @return Amount of pending rewards for specific user
    /// @dev To be used in UI
    function pendingShare(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _rewardTokens = (_generatedReward * pool.allocPoint) / totalAllocPoint;
            accRewardTokenPerShare = accRewardTokenPerShare + ((_rewardTokens * 1e18) / tokenSupply);
        }
        return ((user.amount * accRewardTokenPerShare) / 1e18) - user.rewardDebt;
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
    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        require(_token != rewardToken, "Cannot withdraw reward token");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            require(_token != pool.token, "Cannot withdraw pool tokens");
        }
        _token.safeTransfer(_to, _amount);
        emit RecoverUnsupported(msg.sender, address(_token), _amount, _to);
    }

    /// Add a new pool.
    /// @param _allocPoint Allocations points assigned to the pool
    /// @param _token Address of token to be staked in the pool
    /// @param _depositFee Deposit fee in % (where 100 == 1%)
    /// @param _lastRewardTime Start time of the emissions from the pool
    /// @dev Can only be called by the Operator.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        uint16 _depositFee,
        uint256 _lastRewardTime
    ) public onlyOperator {
        _token.balanceOf(address(this)); // guard to revert calls that try to add non-IERC20 addresses
        require(_depositFee <= 4000, "Deposit fee cannot be higher than 40%");
        checkPoolDuplicate(_token);
        uint256 lastRewardTime = _lastRewardTime;
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (lastRewardTime == 0) {
                lastRewardTime = poolStartTime;
            } else {
                if (lastRewardTime < poolStartTime) {
                    lastRewardTime = poolStartTime;
                }
            }
        } else {
            massUpdatePools();
            // chef is cooking
            if (lastRewardTime == 0 || lastRewardTime < block.timestamp) {
                lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted = (lastRewardTime <= poolStartTime) || (lastRewardTime <= block.timestamp);
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardTime: lastRewardTime,
                accRewardTokenPerShare: 0,
                depositFee: _depositFee,
                isStarted: _isStarted
            })
        );
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
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFee
    ) public onlyOperator {
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

    function setRewardTokensPerSecond(uint256 _rewardTokensPerSecond) public onlyOperator {
        massUpdatePools();
        rewardTokensPerSecond = _rewardTokensPerSecond;
        emit SetRewardTokensPerSecond(msg.sender, _rewardTokensPerSecond);
    }

    /// Return amount of accumulated rewards over the given time, according to the reward tokens per second emission.
    /// @param _fromTime Time from which the generated rewards should be calculated
    /// @param _toTime Time to which the generated rewards should be calculated
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime <= poolStartTime) return 0;
        if (_fromTime <= poolStartTime) return (_toTime - poolStartTime) * rewardTokensPerSecond;
        return (_toTime - _fromTime) * rewardTokensPerSecond;
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
            uint256 _rewardTokens = (_generatedReward * pool.allocPoint) / totalAllocPoint;
            pool.accRewardTokenPerShare = pool.accRewardTokenPerShare + ((_rewardTokens * 1e18) / tokenSupply);
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
            uint256 _pending = ((user.amount * pool.accRewardTokenPerShare) / 1e18) - user.rewardDebt;
            if (_pending > 0) {
                require(
                    rewardToken.balanceOf(address(this)) >= _pending,
                    "Too little rewards in contract to pay to user"
                );
                rewardToken.safeTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            if (pool.depositFee > 0) {
                uint256 depositFeeAmount = (_amount * pool.depositFee) / 10000;
                uint256 _amountMinusFee = _amount - depositFeeAmount;
                pool.token.safeTransferFrom(_sender, feeCollector, depositFeeAmount);
                pool.token.safeTransferFrom(_sender, address(this), _amountMinusFee);
                user.amount = user.amount + (_amountMinusFee);
            } else {
                pool.token.safeTransferFrom(_sender, address(this), _amount);
                user.amount = user.amount + _amount;
            }
        }
        user.rewardDebt = (user.amount * pool.accRewardTokenPerShare) / 1e18;
        emit Deposit(_sender, _pid, _amount, pool.depositFee);
    }

    /// Withdraw tokens from a pool.
    /// @param _pid Id of the chosen pool
    /// @param _amount Amount of tokens to be withdrawn from the pool
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "Withdraw amount greater than users deposited amount");
        updatePool(_pid);
        uint256 _pending = ((user.amount * pool.accRewardTokenPerShare) / 1e18) - user.rewardDebt;
        if (_pending > 0) {
            require(
                rewardToken.balanceOf(address(this)) >= _pending,
                "Too low contract reward token balance to withdraw"
            );
            rewardToken.safeTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = (user.amount * pool.accRewardTokenPerShare) / 1e18;
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

    /// Check if a pool already exists for specified token.
    /// @param _token Address of token to check for existing pools
    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "Pool already exists");
        }
    }
}