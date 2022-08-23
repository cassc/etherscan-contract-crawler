// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Note that this pool has no minter key of SR (rewards).
// Instead, the governance will call SR distributeReward method and send reward to this pool at the beginning.
contract SudoRareGenesisPool is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // governance
    address public operator;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SR to distribute.
        uint256 lastRewardTime; // Last time that SR distribution occurs.
        uint256 accSrPerShare; // Accumulated SR per share, times 1e18.
        bool isStarted; // if lastRewardBlock has passed
    }

    IERC20Upgradeable public sr;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // The time when SR mining starts.
    uint256 public poolStartTime;

    // The time when SR mining ends.
    uint256 public poolEndTime;


    // MAINNET
    uint256 public srPerSecond; // 240.354938272 ether =  62_300_000  SR / 72h
    uint256 public runningTime; // 3 days
    uint256 public constant TOTAL_REWARDS = 62_300_000 ether; // 70% for $XMON $LOOKS $WETH stakers
    // END MAINNET

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event RewardPaid(address indexed user, uint256 amount);

    function initialize(address _sr, uint256 _poolStartTime)
        external
        initializer
    {
        __Ownable_init();
        require(block.timestamp < _poolStartTime, "_poolStartTime: Too late!");
        if (_sr != address(0)) sr = IERC20Upgradeable(_sr);
        poolStartTime = _poolStartTime;
        runningTime = 3 days;
        totalAllocPoint = 0;
        srPerSecond = 240.354938272 ether;
        poolEndTime = poolStartTime + runningTime;
        operator = msg.sender;
    }

    modifier onlyOperator() {
        require(
            operator == msg.sender,
            "SrGenesisPool: caller is not the operator!"
        );
        _;
    }

    function checkPoolDuplicate(IERC20Upgradeable _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(
                poolInfo[pid].token != _token,
                "SrGenesisPool: existing pool!"
            );
        }
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20Upgradeable _token,
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
        bool _isStarted = (_lastRewardTime <= poolStartTime) ||
            (_lastRewardTime <= block.timestamp);
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardTime: _lastRewardTime,
                accSrPerShare: 0,
                isStarted: _isStarted
            })
        );
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's SR allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOperator {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
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
                return poolEndTime.sub(poolStartTime).mul(srPerSecond);
            return poolEndTime.sub(_fromTime).mul(srPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime)
                return _toTime.sub(poolStartTime).mul(srPerSecond);
            return _toTime.sub(_fromTime).mul(srPerSecond);
        }
    }

    // View function to see pending SR on frontend.
    function pendingSR(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSrPerShare = pool.accSrPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));

        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 _srReward = _generatedReward.mul(pool.allocPoint).div(
                totalAllocPoint
            );
            accSrPerShare = accSrPerShare.add(
                _srReward.mul(1e18).div(tokenSupply)
            );
        }
        return user.amount.mul(accSrPerShare).div(1e18).sub(user.rewardDebt);
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
            uint256 _srReward = _generatedReward.mul(pool.allocPoint).div(
                totalAllocPoint
            );
            pool.accSrPerShare = pool.accSrPerShare.add(
                _srReward.mul(1e18).div(tokenSupply)
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
            uint256 _pending = user
                .amount
                .mul(pool.accSrPerShare)
                .div(1e18)
                .sub(user.rewardDebt);
            if (_pending > 0) {
                safeSrTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount.mul(9900).div(10000));
        }
        user.rewardDebt = user.amount.mul(pool.accSrPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "Withdraw: _amount too high!");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accSrPerShare).div(1e18).sub(
            user.rewardDebt
        );
        if (_pending > 0) {
            safeSrTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSrPerShare).div(1e18);
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

    // Safe SR transfer function, just in case a rounding error causes pool to not have enough SRs.
    function safeSrTransfer(address _to, uint256 _amount) internal {
        uint256 _srBalance = sr.balanceOf(address(this));
        if (_srBalance > 0) {
            if (_amount > _srBalance) {
                sr.safeTransfer(_to, _srBalance);
            } else {
                sr.safeTransfer(_to, _amount);
            }
        }
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function governanceRecoverUnsupported(
        IERC20Upgradeable _token,
        uint256 amount,
        address to
    ) external onlyOperator {
        if (block.timestamp < poolEndTime + 90 days) {
            // do not allow to drain core token (SR or lps) if less than 90 days after pool ends
            require(_token != sr, "sr");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "Wrong token!");
            }
        }
        _token.safeTransfer(to, amount);
    }
}