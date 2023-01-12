// Live deployment v3

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Note that this pool has no minter key of share (rewards).
// Instead, the governance will call share distributeReward method and send reward to this pool at the beginning.

contract ShareRewardPool is Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // governance
    address public operator;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Share to distribute per block.
        uint256 lastRewardTime; // Last time that share distribution occurs.
        uint16  depositFeeBP; //depositfee
        uint256 accTokensPerShare; // Accumulated share per share, times 1e18. See below.
        bool isStarted; // if lastRewardTime has passed
    }

    IERC20 public share;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when share mining starts.
    uint256 public poolStartTime;

    // the fee address
    address public feeAddress;

    // The time when share mining ends.
    uint256 public poolEndTime;

    uint256 public sharesPerSecond = 0.0009384384 ether; // 30000 share / (370 days * 24h * 60min * 60s)
    uint256 public runningTime = 370 days; // 370 days
    uint256 public constant TOTAL_REWARDS = 30000 ether;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    function init (address _share, uint256 _poolStartTime)  external initializer {
        require(block.timestamp < _poolStartTime, "late");
        if (_share != address(0)) share = IERC20(_share);

        // ensure source of these rewards is present
        uint256 shareBal = share.balanceOf(address(this));
        uint256 rewardCalc = runningTime * sharesPerSecond;
        require(shareBal >= TOTAL_REWARDS, "rewards missing");
        require(rewardCalc <= TOTAL_REWARDS, "rewards missing");

        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
        operator = msg.sender;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "ShareRewardPool: caller is not the operator");
        _;
    }


    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "ShareRewardPool: existing pool?");
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint16  _depositFeeBP
    ) public onlyOperator {
        require(_depositFeeBP <= 100, "add: invalid deposit fee basis points");
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
            accTokensPerShare : 0,
            isStarted : _isStarted, 
            depositFeeBP: _depositFeeBP
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's share allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint,  uint16 _depositFeeBP) public onlyOperator {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return accumulate rewards over the given _from to _to block.
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

    // View function to see pending Share on frontend.
    function pendingShare(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokensPerShare = pool.accTokensPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _sharesReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accTokensPerShare = accTokensPerShare.add(_sharesReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accTokensPerShare).div(1e18).sub(user.rewardDebt);
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
            uint256 _sharesReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accTokensPerShare = pool.accTokensPerShare.add(_sharesReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accTokensPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeShareTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }


        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
           
           }
             if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.token.safeTransfer(feeAddress, depositFee);

                user.amount = user.amount.add(_amount).sub(depositFee);
             }
             else {
                user.amount = user.amount.add(_amount);
            }
     
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }


    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accTokensPerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeShareTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(1e18);
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

    // Safe share transfer function, just in case if rounding error causes pool to not have enough share.
    function safeShareTransfer(address _to, uint256 _amount) internal {
        uint256 _shareBal = share.balanceOf(address(this));
        if (_shareBal > 0) {
            if (_amount > _shareBal) {
                share.safeTransfer(_to, _shareBal);
            } else {
                share.safeTransfer(_to, _amount);
            }
        }
    }

    function setFeeAddress(address _feeAddress) external onlyOperator {
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

}