// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../owner/Operator.sol";

contract DIARewardPool is Operator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. DIAs to distribute per block.
        uint256 lastRewardTime; // Last time that DIAs distribution occurs.
        uint256 accDIAPerShare; // Accumulated DIAs per share, times 1e18. See below.
        bool isStarted; // if lastRewardTime has passed
        uint256 depositFee; // deposit fee
        uint256 withdrawFee; // withdraw fee
    }

    IERC20 public diamond;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // Fee collector address
    address public feeCollector;

    // The time when DIA mining starts.
    uint256 public poolStartTime;

    // The time when DIA mining ends.
    uint256 public poolEndTime;

    uint256 public diamondPerSecond = 0.00024511 ether; // 7730 DIA / (365 days * 24h * 60min * 60s)
    uint256 public runningTime = 365 days; // 365 days
    uint256 public constant TOTAL_REWARDS = 7730 ether;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event RewardPaid(address indexed user, uint256 amount);

    constructor(address _diamond, uint256 _poolStartTime, address _feeCollector) {
        require(block.timestamp < _poolStartTime, "late");
        require(_diamond != address(0), "Diamond should be non-zero address");
        require(_feeCollector != address(0), "Fee Collector should be non-zero address");

        diamond = IERC20(_diamond);
        feeCollector = _feeCollector;
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(
                poolInfo[pid].token != _token,
                "This pool already exist"
            );
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        uint256 _depositFee,
        uint256 _withdrawFee,
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
                lastRewardTime: _lastRewardTime,
                accDIAPerShare: 0,
                isStarted: _isStarted,
                depositFee: _depositFee,
                withdrawFee: _withdrawFee
            })
        );
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's DIA allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFee, uint256 _withdrawFee) public onlyOperator {
        require(_depositFee < 10000, "deposit fee should be less than 10000");
        require(_withdrawFee < 10000, "withdraw fee should be less than 10000");

        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
        }
        pool.allocPoint = _allocPoint;
        pool.depositFee = _depositFee;
        pool.withdrawFee = _withdrawFee;
    }

    // Set Fee Collector address
    function setFeeCollector(address _feeCollector) public onlyOperator {
        require(_feeCollector != address(0), "Fee collector should be non-zero address");
        feeCollector = _feeCollector;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime)
        public
        view
        returns (uint256)
    {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime)
                return poolEndTime.sub(poolStartTime).mul(diamondPerSecond);
            return poolEndTime.sub(_fromTime).mul(diamondPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime)
                return _toTime.sub(poolStartTime).mul(diamondPerSecond);
            return _toTime.sub(_fromTime).mul(diamondPerSecond);
        }
    }

    // View function to see pending DIAs on frontend.
    function pendingShare(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDIAPerShare = pool.accDIAPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 _diamondReward = _generatedReward.mul(pool.allocPoint).div(
                totalAllocPoint
            );
            accDIAPerShare = accDIAPerShare.add(
                _diamondReward.mul(1e18).div(tokenSupply)
            );
        }
        return user.amount.mul(accDIAPerShare).div(1e18).sub(user.rewardDebt);
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
            uint256 _generatedReward = getGeneratedReward(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 _diaReward = _generatedReward.mul(pool.allocPoint).div(
                totalAllocPoint
            );
            pool.accDIAPerShare = pool.accDIAPerShare.add(
                _diaReward.mul(1e18).div(tokenSupply)
            );
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
            uint256 _pending = user.amount.mul(pool.accDIAPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeDIATransfer(_sender, _pending);
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
        user.rewardDebt = user.amount.mul(pool.accDIAPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accDIAPerShare).div(1e18).sub(
            user.rewardDebt
        );
        if (_pending > 0) {
            safeDIATransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            if (pool.withdrawFee > 0) {
                uint256 feeAmount = _amount.mul(pool.withdrawFee).div(10000);
                pool.token.safeTransfer(feeCollector, feeAmount);
                pool.token.safeTransfer(_sender, _amount.sub(feeAmount));
                user.amount = user.amount.sub(_amount);
            } else {
                pool.token.safeTransfer(_sender, _amount);
                user.amount = user.amount.sub(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accDIAPerShare).div(1e18);
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

    // Safe DIA transfer function, just in case if rounding error causes pool to not have enough DIAs.
    function safeDIATransfer(address _to, uint256 _amount) internal {
        uint256 _diamondBalance = diamond.balanceOf(address(this));
        if (_diamondBalance > 0) {
            if (_amount > _diamondBalance) {
                diamond.safeTransfer(_to, _diamondBalance);
            } else {
                diamond.safeTransfer(_to, _amount);
            }
        }
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        if (block.timestamp < poolEndTime + 90 days) {
            // do not allow to drain core token (DIA or lps) if less than 90 days after pool ends
            require(_token != diamond, "Shouldn't drain DIA if less than 90 days after pool ends");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "Shouldn't drain staking token & LPs if less than 90 days after pool ends");
            }
        }
        _token.safeTransfer(_to, _amount);
    }
}